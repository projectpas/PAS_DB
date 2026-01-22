CREATE PROCEDURE [dbo].[GetStocklineHistoryById]
	@StockLineId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY 
		
		SELECT M.ModuleName, STL.StockLineNumber,
		CASE WHEN StlHist.ModuleId = 1 THEN (SELECT CustomerCode FROM DBO.Customer WHERE CustomerId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 2 THEN (SELECT VendorCode FROM DBO.Vendor WHERE VendorId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 10 THEN (SELECT SalesOrderNumber FROM DBO.SalesOrder WHERE SalesOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 13 THEN (SELECT PurchaseOrderNumber FROM DBO.PurchaseOrder WHERE PurchaseOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 14 THEN (SELECT RepairOrderNumber FROM DBO.RepairOrder WHERE RepairOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 15 THEN (SELECT WorkOrderNum FROM DBO.WorkOrder WHERE WorkOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 16 THEN (SELECT SubWorkOrderNo FROM DBO.SubWorkOrder WHERE SubWorkOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 18 THEN (SELECT ExchangeSalesOrderNumber FROM DBO.ExchangeSalesOrder WHERE ExchangeSalesOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 22 THEN (SELECT StockLineNumber FROM DBO.Stockline WHERE StocklineId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 24 THEN (SELECT SubWorkOrderNo FROM DBO.SubWorkOrder WHERE SubWorkOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 27 THEN (SELECT ReceivingNumber FROM DBO.ReceivingCustomerWork WHERE ReceivingCustomerWorkId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 28 THEN (SELECT PurchaseOrderNumber FROM DBO.PurchaseOrder WHERE PurchaseOrderId = StlHist.RefferenceId)
		WHEN StlHist.ModuleId = 29 THEN (SELECT RepairOrderNumber FROM DBO.RepairOrder WHERE RepairOrderId = StlHist.RefferenceId)
		END AS RefferenceId,
		StlHist.StocklineHistoryId,
		StlHist.ModuleId,
		StlHist.StocklineId,
		StlHist.QuantityAvailable,
		StlHist.QuantityOnHand,
		StlHist.QuantityReserved,
		StlHist.QuantityIssued,
		StlHist.TextMessage,
		StlHist.CreatedBy,
		StlHist.CreatedDate,
		StlHist.UpdatedBy,
		StlHist.UpdatedDate,
		StlHist.MasterCompanyId FROM DBO.StocklineHistory StlHist 
		INNER JOIN DBO.Module M WITH (NOLOCK) ON StlHist.ModuleId = M.ModuleId
		INNER JOIN DBO.Stockline STL WITH (NOLOCK) ON StlHist.StocklineId = STL.StockLineId
		WHERE StlHist.StocklineId = @StockLineId
		ORDER BY StlHist.CreatedDate DESC
	END TRY
	BEGIN CATCH
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'GetPNManufacturerCombinationCreated' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH 
END