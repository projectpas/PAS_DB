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
	
 --  EXEC RPT_GetCreditMemoPartsForPrint 131,0,13
**************************************************************/ 

CREATE   PROCEDURE [dbo].[RPT_GetCreditMemoPartsForPrint]
@InvoicingId bigint,
@IsWorkOrder bit,
@CreditMemoHeaderId bigint
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
	BEGIN TRY
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
					   SOPN.CustomerReference,
					   IM.PurchaseUnitOfMeasure AS UOM,
					   CM.Qty,
					   CM.UnitPrice,
					   CM.Amount						
				FROM dbo.CreditMemoDetails CM WITH (NOLOCK)						
					LEFT JOIN dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON CM.InvoiceId = SOBI.SOBillingInvoicingId
					LEFT JOIN  dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId
					LEFT JOIN  dbo.SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId AND CM.StocklineId = SOPN.StockLineId
					LEFT JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = SOPN.ConditionId
					LEFT JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON CM.ItemMasterId=IM.ItemMasterId
				WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId;
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
					   CM.UnitPrice,
					   CM.Amount
				 FROM dbo.CreditMemoDetails CM WITH (NOLOCK)  
					LEFT JOIN dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId
					LEFT JOIN  dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
					LEFT JOIN  dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId AND CM.StocklineId = WOPN.StockLineId				
					LEFT JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = WOPN.ConditionId
					LEFT JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId				
				WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId;
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