/***************************************************************  
 ** File:  [USP_GetWorkOrderTypeIdAndShippingName]       
 ** Author:   Priyansh Patel
 ** Description: Get WorkOrderTypeId, ShippingName and ship to Customer details
 ** Date:  05-Nov-2025
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    05-Nov-2025		Priyansh Patel			Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
 
--EXEC [dbo].[USP_GetWorkOrderTypeIdAndShippingName] @WoPartNoId = 4348,@ShipviaId = 32459,@ShippingName = 'hong1',@ShipToCustomerId = 44,@WorkOrderId = 10052,@MasterCompanyId=1

**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetWorkOrderTypeIdAndShippingName]
    @WoPartNoId BIGINT,
    @ShipviaId BIGINT,
    @ShippingName VARCHAR(100),
    @ShipToCustomerId BIGINT,
	@WorkOrderId  BIGINT,
	@MasterCompanyId INT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

BEGIN TRY
			DECLARE @ShippingViaName NVARCHAR(200);
			DECLARE @TemplatedBody NVARCHAR(MAX);
			DECLARE @ShipToCustomer NVARCHAR(200);
			DECLARE @WorkOrderTypeId INT;

			SELECT TOP 1 @ShippingViaName = [Name] FROM [dbo].[ShippingVia] WITH(NOLOCK) WHERE [ShippingViaId] = @ShipviaId AND [MasterCompanyId] = @MasterCompanyId;

			SELECT TOP 1 @TemplatedBody = [TemplateBody] FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE [TemplateCode] = @ShippingName;
					   
			SELECT TOP 1 @ShipToCustomer = [Name] FROM [dbo].[Customer] WITH(NOLOCK) WHERE [CustomerId] = @ShipToCustomerId	AND [MasterCompanyId] = @MasterCompanyId;

			SELECT TOP 1 @WorkOrderTypeId = [WorkOrderTypeId] FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId	AND [MasterCompanyId] = @MasterCompanyId;

			SELECT	WOP.ItemMasterId, 
			        IM.PartNumber AS MPNPartNumber,
					@ShippingViaName AS ShippingViaName,
					@TemplatedBody AS TemplatedBody,
					@ShipToCustomer AS ShipToCustomer,
					@WorkOrderTypeId AS WorkOrderTypeId
			FROM [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK)
			LEFT JOIN [dbo].[ItemMaster] IM WITH(NOLOCK) ON IM.[ItemMasterId] = WOP.[ItemMasterId]
			 AND ISNULL(IM.IsNonStock,0) = 0
			 WHERE WOP.[ID] = @WoPartNoId AND WOP.[MasterCompanyId] = @MasterCompanyId;

END TRY

	BEGIN CATCH
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments varchar(150) = '[USP_GetWorkOrderTypeIdAndShippingName]',
			@ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@WorkOrderId AS VARCHAR(100)) ,'') +'
												   @Parameter2 = ' + ISNULL(CAST(@ShipviaId AS VARCHAR(100)) ,'') +'
												   @Parameter3 = ' + ISNULL(CAST(@ShippingName AS VARCHAR(100)) ,'') +'
												   @Parameter4 = ' + ISNULL(CAST(@ShipToCustomerId AS VARCHAR(100)) ,'') +'
												   @Parameter5 = ' + ISNULL(CAST(@WorkOrderId AS VARCHAR(100)) ,'') +'',
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END