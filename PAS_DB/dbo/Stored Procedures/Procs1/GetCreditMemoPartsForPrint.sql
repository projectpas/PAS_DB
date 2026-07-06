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
	2	 02/1/2024	  AMIT GHEDIYA	added isperforma Flage for SO
	3    10/16/2024	  Abhishek Jirawla	Implemented the new tables for SalesOrder related tables
	4    03-07-2025   Moin Bloch        Changed Old To New Billing Table
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	
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
		DECLARE @WOModuleId INT,@SOModuleId INT,@EXModuleId INT
		SELECT @WOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'WorkOrder';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'SalesOrder';
		SELECT @EXModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'ExchangeSalesOrder';
		IF(@IsWorkOrder = 0)
		BEGIN
				SELECT CM.InvoiceId,	
					   CM.PartNumber,
					   CM.PartDescription,
					   CO.Code AS 'Codition',
					   SOBI.InvoiceNo,
					   --SOPN.CustomerReference,
					   '' AS CustomerReference,
					   IM.PurchaseUnitOfMeasure AS UOM,
					   CM.Qty,
					   CM.UnitPrice,
					   CM.Amount						
				FROM dbo.CreditMemoDetails CM WITH (NOLOCK)						
					INNER JOIN dbo.BillingInvoicing SOBI WITH (NOLOCK) ON CM.InvoiceId = SOBI.BillingInvoicingId AND ISNULL(SOBI.IsPerformaInvoice,0) = 0
					INNER JOIN  dbo.BillingInvoicingItems SOBII WITH (NOLOCK) ON SOBII.BillingInvoicingId = SOBI.BillingInvoicingId AND ISNULL(SOBII.IsPerformaInvoice,0) = 0
					INNER JOIN  dbo.SalesOrderPartV1 SOPN WITH (NOLOCK) ON SOPN.SalesOrderId =SOBI.ReferenceId AND SOPN.SalesOrderPartId = SOBII.SubReferenceId
					INNER JOIN  dbo.SalesOrderStocklineV1 SOV WITH (NOLOCK) ON CM.StocklineId = SOV.StockLineId
					INNER JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = SOPN.ConditionId
					INNER JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON CM.ItemMasterId=IM.ItemMasterId
				WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId AND SOBI.[ModuleId] = @SOModuleId
		 AND ISNULL(IM.IsNonStock,0) = 0
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
					INNER JOIN dbo.BillingInvoicing WOBI WITH (NOLOCK) ON CM.InvoiceId = WOBI.BillingInvoicingId
					INNER JOIN  dbo.BillingInvoicingItems WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
					INNER JOIN  dbo.WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.ReferenceId AND WOPN.ID = WOBII.SubReferenceId AND CM.StocklineId = WOPN.StockLineId				
					INNER JOIN  dbo.Condition CO WITH (NOLOCK) ON CO.ConditionId = WOPN.RevisedConditionId
					INNER JOIN  dbo.ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId				
				WHERE CM.InvoiceId=@InvoicingId AND CM.CreditMemoHeaderId=@CreditMemoHeaderId AND WOBI.[ModuleId] = @WOModuleId
		 AND ISNULL(IM.IsNonStock,0) = 0
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