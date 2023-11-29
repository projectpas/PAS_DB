
/*************************************************************           
 ** File:   [GetCreditMemoPartsForPrint]           
 ** Author: Moin Bloch
 ** Description: Get Customer RMAPartsDetails
 ** Purpose:         
 ** Date:   11-05-2022     
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/20/2022   Moin Bloch    Created
	
 --  EXEC GetCreditMemoPartsForPrint 93,0,38
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetCreditMemoPartsForPrint]
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
				SELECT CM.InvoiceId,	
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
					INNER JOIN dbo.SalesOrderBillingInvoicing SOBI WITH (NOLOCK) ON CM.InvoiceId = SOBI.SOBillingInvoicingId
					INNER JOIN  dbo.SalesOrderBillingInvoicingItem SOBII WITH (NOLOCK) ON SOBII.SOBillingInvoicingId = SOBI.SOBillingInvoicingId
					INNER JOIN  dbo.SalesOrderPart SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.SalesOrderId AND SOPN.SalesOrderPartId = SOBII.SalesOrderPartId AND CM.StocklineId = SOPN.StockLineId
					INNER JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = SOPN.ConditionId
					INNER JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON CM.ItemMasterId=IM.ItemMasterId
				WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId;
		END
		ELSE 
		BEGIN
				SELECT CM.InvoiceId,	
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
					INNER JOIN dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId
					INNER JOIN  dbo.WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
					INNER JOIN  dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId AND CM.StocklineId = WOPN.StockLineId				
					INNER JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = WOPN.ConditionId
					INNER JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId				
				WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId;
		END
	END TRY    
	BEGIN CATCH      
	IF @@trancount > 0				
	ROLLBACK TRAN;
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
    , @AdhocComments     VARCHAR(150)    = 'GetCreditMemoPartsForPrint' 
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