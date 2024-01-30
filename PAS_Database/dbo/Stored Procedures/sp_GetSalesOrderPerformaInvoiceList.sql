/*************************************************************           
 ** File:   [dbo].[sp_GetSalesOrderPerformaInvoiceList]          
 ** Author:   AMIT GHEDIYA
 ** Description: Get Performa Invoice Data.
 ** Date:   01/29/2024   
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1    01/29/2024   AMIT GHEDIYA			Created

--   EXEC sp_GetSalesOrderPerformaInvoiceList 814
**************************************************************/ 
CREATE     PROCEDURE [dbo].[sp_GetSalesOrderPerformaInvoiceList]
	@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT DISTINCT so.SalesOrderNumber, 
								imt.partnumber, 
								imt.PartDescription, 
								sop.ConditionId, 				
								sop.SalesOrderId, 
								imt.ItemMasterId AS SalesOrderPartId,				
								'' AS [Status],
								0 AS ItemNo  
						FROM DBO.SalesOrderPart sop WITH (NOLOCK)
							LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
							LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
							LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = sop.StockLineId
							LEFT JOIN DBO.SalesOrderBillingInvoicing sobi WITH (NOLOCK) ON sobi.SalesOrderId = sop.SalesOrderId
							LEFT JOIN DBO.SalesOrderBillingInvoicingItem sobii WITH (NOLOCK) ON sobii.SOBillingInvoicingId = sobi.SOBillingInvoicingId
										AND sobii.SalesOrderPartId = sop.SalesOrderPartId AND sobii.NoofPieces = sop.Qty
										AND sobii.IsVersionIncrease = 0
							LEFT JOIN DBO.SalesOrderReserveParts SOR WITH (NOLOCK) ON SOR.SalesOrderPartId = sop.SalesOrderPartId
							LEFT JOIN DBO.SalesOrderShipping sos WITH (NOLOCK) ON sos.SalesOrderId = sop.SalesOrderId
							LEFT JOIN DBO.SalesOrderShippingItem sosi WITH (NOLOCK) ON sos.SalesOrderShippingId = sosi.SalesOrderShippingId AND sosi.SalesOrderPartId = sop.SalesOrderPartId
						WHERE sop.SalesOrderId = @SalesOrderId --AND ISNULL(sop.StockLineId,0) >0
						GROUP BY so.SalesOrderNumber, imt.partnumber, imt.PartDescription,
							sop.SalesOrderId, imt.ItemMasterId, sop.Qty, sop.ConditionId;
			END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_GetSalesOrderPerformaInvoiceList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END