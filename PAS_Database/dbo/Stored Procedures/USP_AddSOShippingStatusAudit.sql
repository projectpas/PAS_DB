/*************************************************************
 ** File:   [USP_AddSOShippingStatusAudit]
 ** Author:  Vishal Suthar
 ** Description: Adds the shipping status change (Shipped / Canceled) of a SO shipment to the SO Audit History
 ** Purpose:  [PN-18475] SO Shipping status changes in SO Audit History
 ** Date:   05-11-2026
 ** PARAMETERS: @SalesOrderShippingId BIGINT, @UpdatedBy VARCHAR(256)
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    05-11-2026   Vishal Suthar		Created

 EXEC [dbo].[USP_AddSOShippingStatusAudit] @SalesOrderShippingId = 1, @UpdatedBy = 'ADMIN User'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddSOShippingStatusAudit]
	@SalesOrderShippingId BIGINT,
	@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		-- Same columns as trg_Audit_dbo_SalesOrder, the rest come from the AuditLog defaults
		INSERT INTO [dbo].[AuditLog] ([SchemaName], [TableName], [PKJson], [ColumnName], [Action], [OldValue], [NewValue], [UpdatedBy])
		SELECT 'dbo', 'SalesOrder', CONCAT('{"SalesOrderId":', SOS.[SalesOrderId], '}'), 'ShippingStatus', 'U', NULL,
			CONCAT(SOS.[SOShippingNum], ' - ', SS.[Status]), @UpdatedBy
		FROM [dbo].[SalesOrderShipping] SOS WITH(NOLOCK)
		INNER JOIN [dbo].[ShippingStatus] SS WITH(NOLOCK) ON SS.[ShippingStatusId] = SOS.[SOShippingStatusId]
		WHERE SOS.[SalesOrderShippingId] = @SalesOrderShippingId;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_AddSOShippingStatusAudit'
			, @ProcedureParameters VARCHAR(3000) = '@SalesOrderShippingId = ''' + CAST(ISNULL(@SalesOrderShippingId, '') AS VARCHAR(100))
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException
			@DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN(1);
	END CATCH
END
