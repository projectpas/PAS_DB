/************************************************************************************           
 ** File:   [SubWorkOrderDetails]           
 ** Author: 
 ** Description: This stored procedure is used to get SubWorkOrderDetails.
 ** Purpose:         
 ** Date:   

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************************************           
  ** Change History           
 **************************************************************************************           
 ** PR    Date					Author				Change Description            
 ** --    --------			-----------				--------------------------------          
	 1    4-10-2025			Amit Ghediya			Created
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	3    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	 EXEC [dbo].[SubWorkOrderDetails] 282
****************************************************************************************/
CREATE PROCEDURE [dbo].[SubWorkOrderDetails]
	@SubWorkOrderId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY

				SELECT TOP 1
					SWO.SubWorkOrderId,
					SWO.SubWorkOrderNo,
					WO.WorkOrderNum,
					IM.PartNumber AS MCPN,
					IM.PartDescription AS MCPNDescription,
					SL.SerialNumber AS MCSerialNum,
					CUST.Name AS CustName,
					SL.StockLineNumber AS Stockline,
					WO.WorkOrderTypeId,
					SWO.OpenDate,
					WO.FunctionalCurrencyId AS CurrencyId,
					ISNULL(FCU.Code, '') AS FunctionalCurrency,
					ISNULL(RCU.Code, '') AS ReportCurrency,
					CASE 
						WHEN WO.ForeignExchangeRate > 0 THEN WO.ForeignExchangeRate 
						ELSE 0 
					END AS ForeignExchangeRate
				FROM [DBO].[SubWorkOrder] SWO WITH(NOLOCK)
				INNER JOIN [DBO].[WorkOrder] WO WITH(NOLOCK) ON SWO.WorkOrderId = WO.WorkOrderId
				INNER JOIN [DBO].[StockLine] SL WITH(NOLOCK) ON SWO.StockLineId = SL.StockLineId
				INNER JOIN [DBO].[ItemMaster] IM WITH(NOLOCK) ON SL.ItemMasterId = IM.ItemMasterId
				INNER JOIN [DBO].[Customer] CUST WITH(NOLOCK) ON WO.CustomerId = CUST.CustomerId
				LEFT JOIN [DBO].[Currency] FCU WITH(NOLOCK) ON WO.FunctionalCurrencyId = FCU.CurrencyId AND FCU.IsActive = 1 AND FCU.IsDeleted = 0
				LEFT JOIN [DBO].[Currency] RCU WITH(NOLOCK) ON WO.ReportCurrencyId = RCU.CurrencyId AND RCU.IsActive = 1 AND RCU.IsDeleted = 0
				WHERE SWO.SubWorkOrderId = @SubWorkOrderId AND ISNULL(IM.IsNonStock,0) = 0 AND ISNULL(SL.IsNonStock,0) = 0 ;

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SubWorkOrderDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderId, '')
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END