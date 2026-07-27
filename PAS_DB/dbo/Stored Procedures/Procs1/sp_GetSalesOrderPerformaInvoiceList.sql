-- ===== PROCEDURE: [dbo].[sp_GetSalesOrderPerformaInvoiceList]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs1/sp_GetSalesOrderPerformaInvoiceList.sql) =====
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
	2	 11/04/2024	  Vishal Suthar			Modified to make use of new SO Part tables
	3    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	4    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
	5    20/July/2026			 RAJESH GAMI						[PN-17350] - Removed IsNonStock=0 filter(s) so Non-Stock parts appear/populate correctly on SO performa invoice list.

--   EXEC sp_GetSalesOrderPerformaInvoiceList 814
**************************************************************/ 
CREATE   PROCEDURE [dbo].[sp_GetSalesOrderPerformaInvoiceList]
	@SalesOrderId  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			   DECLARE @SOModuleId INT
		       SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

				SELECT DISTINCT so.SalesOrderNumber, 
								imt.partnumber, 
								imt.PartDescription, 
								sop.ConditionId, 				
								sop.SalesOrderId, 
								imt.ItemMasterId AS SalesOrderPartId,				
								'' AS [Status],
								0 AS ItemNo,
								sop.QtyOrder AS Qty
						FROM DBO.SalesOrderPartV1 sop WITH (NOLOCK)
							LEFT JOIN DBO.SalesOrderStocklineV1 stk WITH (NOLOCK) ON stk.SalesOrderPartId = sop.SalesOrderPartId
							LEFT JOIN DBO.SalesOrder so WITH (NOLOCK) ON so.SalesOrderId = sop.SalesOrderId
							LEFT JOIN DBO.ItemMaster imt WITH (NOLOCK) ON imt.ItemMasterId = sop.ItemMasterId
							 LEFT JOIN DBO.Stockline sl WITH (NOLOCK) ON sl.StockLineId = stk.StockLineId
							LEFT JOIN DBO.BillingInvoicing sobi WITH (NOLOCK) ON sobi.ReferenceId = sop.SalesOrderId AND ISNULL(sobi.IsPerformaInvoice,0) = 1 AND sobi.[ModuleId] = @SOModuleId
							LEFT JOIN DBO.BillingInvoicingItems sobii WITH (NOLOCK) ON sobii.BillingInvoicingId = sobi.BillingInvoicingId AND ISNULL(sobii.IsPerformaInvoice,0) = 1
										AND sobii.SubReferenceId = sop.SalesOrderPartId AND sobii.QtyBilled = sop.QtyOrder
										AND ISNULL(sobii.IsVersionIncrease,0) = 0
						WHERE sop.SalesOrderId = @SalesOrderId AND sobi.[ModuleId] = @SOModuleId --AND ISNULL(sop.StockLineId,0) >0
						GROUP BY so.SalesOrderNumber, imt.partnumber, imt.PartDescription,
							sop.SalesOrderId, imt.ItemMasterId, sop.QtyOrder, sop.ConditionId;
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