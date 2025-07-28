/*************************************************************           
 ** File:   [RPT_GetCreditMemoPartsForPrint]           
 ** Author: Amit Ghediya
 ** Description: Get Customer RMAPartsDetails for SSRS Report
 ** Purpose:         
 ** Date:   04/21/2023    
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/21/2023   Amit Ghediya    Created
	2	 01/02/2024	  AMIT GHEDIYA	  added isperforma Flage for SO
	3	 04/01/2024	  HEMANT SALIYA	  added isperforma Flage for SO
	4    04/12/2024   HEMANT SALIYA   Updated Status Id 
	5	 11/04/2024	  Vishal Suthar	  Modified to make use of new SO Part tables
	6    26/06/2025	  AMIT GHEDIYA	  Modified to make use of new common Billing tables
	
 --  EXEC RPT_GetCreditMemoPartsForPrint 546,1,190
**************************************************************/ 

CREATE    PROCEDURE [dbo].[RPT_GetCreditMemoPartsForPrint]
@InvoicingId bigint,
@IsWorkOrder bit,
@CreditMemoHeaderId bigint
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
		
		DECLARE @WOModuleId INT,
				@SOModuleId INT;
	
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';

		IF(@IsWorkOrder = 0)
		BEGIN
				SELECT 
					   ROW_NUMBER() OVER (
						ORDER BY CM.CreditMemoDetailId
					   ) row_num, 
					   CM.InvoiceId,	
					   CM.PartNumber,
					   CM.PartDescription,
					   CO.Code AS 'Codition',
					   SOBI.InvoiceNo,
					   SO.CustomerReference,
					   IM.PurchaseUnitOfMeasure AS UOM,
					   CM.Qty,
					   --ABS(CM.UnitPrice) UnitPrice,
					   ABS(ISNULL(CM.PartsUnitCost, 0)) UnitPrice,
					   (ISNULL(CM.PartsRevenue, 0) + ISNULL(CM.LaborRevenue, 0)) SubTotal, --+ ISNULL(CM.FreightRevenue, 0) + ISNULL(CM.MiscRevenue, 0)
					   --(ISNULL(CM.PartsRevenue, 0) + ISNULL(CM.LaborRevenue, 0) + ISNULL(CM.FreightRevenue, 0) + ISNULL(CM.MiscRevenue, 0) + ISNULL(CM.SalesTax, 0) + ISNULL(CM.OtherTax, 0)) SubTotal,
					   CM.RestockingFee,
					   ABS(CM.Amount) Amount						
				FROM dbo.CreditMemoDetails CM WITH (NOLOCK)		
					LEFT JOIN  dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingItemId = CM.BillingInvoicingItemId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
					LEFT JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
					LEFT JOIN  dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId = SOBI.ReferenceId AND SOPN.SalesOrderPartId = SOBII.SubReferenceId
					LEFT JOIN  dbo.SalesOrderStocklineV1 SOPStk WITH (NOLOCK) ON SOPStk.SalesOrderPartId = SOBII.SubReferenceId AND CM.StocklineId = SOPStk.StockLineId
					LEFT JOIN  dbo.SalesOrder SO WITH (NOLOCK) ON SO.SalesOrderId = SOBI.ReferenceId
					LEFT JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = SOPN.ConditionId
					LEFT JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON CM.ItemMasterId = IM.ItemMasterId
				WHERE CM.InvoiceId = @InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId AND SOBI.ModuleId = @SOModuleId;
		END
		ELSE 
		BEGIN
				SELECT 
					   ROW_NUMBER() OVER (
						ORDER BY CM.CreditMemoDetailId
					   ) row_num, 
					   CM.InvoiceId,	
					   CM.PartNumber,
					   CM.PartDescription,
					   CO.Code AS 'Codition',
					   WOBI.InvoiceNo,
					   WOPN.CustomerReference,
					   IM.PurchaseUnitOfMeasure AS UOM,
					   CM.Qty,
					   --ABS(CM.UnitPrice) UnitPrice,
					   ABS(ISNULL(CM.PartsUnitCost, 0)) UnitPrice,
					   (ISNULL(CM.PartsRevenue, 0) + ISNULL(CM.LaborRevenue, 0)) SubTotal, -- + ISNULL(CM.FreightRevenue, 0) + ISNULL(CM.MiscRevenue, 0)
					   --(ISNULL(CM.PartsRevenue, 0) + ISNULL(CM.LaborRevenue, 0) + ISNULL(CM.FreightRevenue, 0) + ISNULL(CM.MiscRevenue, 0) + ISNULL(CM.SalesTax, 0) + ISNULL(CM.OtherTax, 0)) SubTotal,
					   CM.RestockingFee,
					   ABS(CM.Amount) Amount	
				 FROM dbo.CreditMemoDetails CM WITH (NOLOCK)  
					LEFT JOIN  dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingItemId = CM.BillingInvoicingItemId
					LEFT JOIN dbo.BillingInvoicing WOBI WITH (NOLOCK) ON WOBII.BillingInvoicingId = WOBI.BillingInvoicingId
					LEFT JOIN  dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId = WOBI.ReferenceId AND WOPN.ID = WOBII.SubReferenceId AND CM.StocklineId = WOPN.StockLineId				
					LEFT JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = WOPN.RevisedConditionId
					LEFT JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId				
				WHERE CM.InvoiceId = @InvoicingId AND CM.CreditMemoHeaderId = @CreditMemoHeaderId AND WOBI.ModuleId = @WOModuleId;
		END
	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0				
	ROLLBACK TRAN;
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    , @AdhocComments     VARCHAR(150)    = 'RPT_GetCreditMemoPartsForPrint' 
    , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@InvoicingId, '') + '''
										   @Parameter2 = ' + ISNULL(CAST(@isWorkOrder AS varchar(10)) ,'') +'
										   @Parameter3 = ' + ISNULL(CAST(@CreditMemoHeaderId AS varchar(10)) ,'') +''													  
    , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END