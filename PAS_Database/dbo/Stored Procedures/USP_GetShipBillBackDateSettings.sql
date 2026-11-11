/*************************************************************
 ** File:   [USP_GetShipBillBackDateSettings]
 ** Author:   Vishal Suthar
 ** Description: Returns the Allow Back Date Shipping / Billing flags of the Legal Entity of a Sales Order, Work Order or Lease
 **              (Legal Entity of the management structure: Sales Order header / Work Order part number / Lease header)
 ** Date:   19/Oct/2026

 ** PARAMETERS:
 **   @ModuleName         - 'SalesOrder', 'WorkOrder' or 'Lease'
 **   @ReferenceId        - SalesOrderId / WorkOrderId / LeaseHeaderId
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author          Change Description
 ** --   --------     -------         --------------------------------
    1    19/Oct/2026  Vishal Suthar   Created
    2    11/Nov/2026  Kishor Makwana  [PN-18520] Added 'Lease' module (Lease Header management structure) for the Lease Shipping Ship Date lock

 EXEC [dbo].[USP_GetShipBillBackDateSettings] 'SalesOrder', 1283
 EXEC [dbo].[USP_GetShipBillBackDateSettings] 'WorkOrder', 4120
 EXEC [dbo].[USP_GetShipBillBackDateSettings] 'Lease', 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetShipBillBackDateSettings]
	@ModuleName VARCHAR(50),
	@ReferenceId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		DECLARE @ManagementStructureId BIGINT = NULL;

		IF (@ModuleName = 'SalesOrder')
		BEGIN
			SELECT @ManagementStructureId = SO.[ManagementStructureId]
			FROM [dbo].[SalesOrder] SO WITH(NOLOCK)
			WHERE SO.[SalesOrderId] = @ReferenceId;
		END
		ELSE IF (@ModuleName = 'WorkOrder')
		BEGIN
			SELECT TOP 1 @ManagementStructureId = WOP.[ManagementStructureId]
			FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)
			WHERE WOP.[WorkOrderId] = @ReferenceId
			  AND ISNULL(WOP.[IsDeleted], 0) = 0
			ORDER BY WOP.[ID];
		END
		ELSE IF (@ModuleName = 'Lease')
		BEGIN
			SELECT @ManagementStructureId = LH.[ManagementStructureId]
			FROM [dbo].[LeaseHeader] LH WITH(NOLOCK)
			WHERE LH.[LeaseHeaderId] = @ReferenceId;
		END

		SELECT
			ISNULL(LE.[AllowBackDateShipping], 0) AS AllowBackDateShipping,
			ISNULL(LE.[AllowBackDateBilling], 0) AS AllowBackDateBilling
		FROM [dbo].[EntityStructureSetup] ESS WITH(NOLOCK)
		INNER JOIN [dbo].[ManagementStructureLevel] MSL WITH(NOLOCK) ON MSL.[ID] = ESS.[Level1Id]
		INNER JOIN [dbo].[LegalEntity] LE WITH(NOLOCK) ON LE.[LegalEntityId] = MSL.[LegalEntityId]
		WHERE ESS.[EntityStructureId] = @ManagementStructureId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'USP_GetShipBillBackDateSettings'
			, @ProcedureParameters VARCHAR(3000) = '@ModuleName = ''' + ISNULL(@ModuleName, '') + ''', @ReferenceId = ''' + CAST(ISNULL(@ReferenceId, '') AS VARCHAR(100))
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName           = @DatabaseName
			, @AdhocComments        = @AdhocComments
			, @ProcedureParameters  = @ProcedureParameters
			, @ApplicationName      = @ApplicationName
			, @ErrorLogID           = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
