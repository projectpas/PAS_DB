/*********************
 ** File:   [PROCInsertCreditMemoDetails]        
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used Save CM Details
 ** Purpose:         
 ** Date:   28 MAR 2024     
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------   
    1    28 MAR 2024	HEMANT SALIYA         Update For Details Level         

**********************/

CREATE    PROCEDURE [dbo].[PROCInsertCreditMemoDetails](@TableCreditMemoDetailsType CreditMemoDetailsType READONLY)    
AS    
BEGIN    
 SET NOCOUNT ON;  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
  BEGIN TRY  
   BEGIN TRANSACTION  
    BEGIN  
		DECLARE @CreditMemoHeaderId AS bigint = 0; 
		IF((SELECT COUNT(CreditMemoHeaderId) FROM @TableCreditMemoDetailsType) > 0 )  
		BEGIN  
			SET @CreditMemoHeaderId = (SELECT TOP 1 CreditMemoHeaderId FROM @TableCreditMemoDetailsType); 
			
			MERGE dbo.CreditMemoDetails AS TARGET  
			USING @TableCreditMemoDetailsType AS SOURCE ON (TARGET.CreditMemoHeaderId = SOURCE.CreditMemoHeaderId AND   
                         TARGET.CreditMemoDetailId = SOURCE.CreditMemoDetailId)   
			WHEN MATCHED   
			THEN UPDATE   
				SET   
				TARGET.[InvoiceId] = SOURCE.InvoiceId,        
				TARGET.[ItemMasterId] = SOURCE.ItemMasterId,  
				TARGET.[PartNumber] = SOURCE.PartNumber,  
				TARGET.[PartDescription] = SOURCE.PartDescription,  
				TARGET.[AltPartNumber] = SOURCE.AltPartNumber,  
				TARGET.[CustPartNumber] = SOURCE.CustPartNumber,  
                TARGET.[SerialNumber] = SOURCE.SerialNumber,  
                TARGET.[Qty]  = SOURCE.Qty,  
                TARGET.[UnitPrice] = SOURCE.UnitPrice,  
                TARGET.[Amount] = SOURCE.Amount,  
				TARGET.[SalesTax] = SOURCE.SalesTax,  
				TARGET.[OtherTax] = SOURCE.OtherTax,  
				TARGET.[PartsRevenue] = SOURCE.PartsRevenue,  
				TARGET.[LaborRevenue] = SOURCE.LaborRevenue,  
				TARGET.[MiscRevenue] = SOURCE.MiscRevenue,  
				TARGET.[FreightRevenue] = SOURCE.FreightRevenue,  
				TARGET.[RestockingFee] = SOURCE.RestockingFee,  
				TARGET.[CogsParts] = SOURCE.CogsParts,  
				TARGET.[CogsLabor] = SOURCE.CogsLabor,  
				TARGET.[CogsOverHeadCost] = SOURCE.CogsOverHeadCost,  
				TARGET.[CogsInventory] = SOURCE.CogsInventory,  
                TARGET.[ReasonId] = SOURCE.ReasonId,  
                TARGET.[Reason] = SOURCE.Reason,  
                TARGET.[StocklineId] = SOURCE.StocklineId,  
                TARGET.[StocklineNumber] = SOURCE.StocklineNumber,  
                TARGET.[ControlNumber] = SOURCE.ControlNumber,  
                TARGET.[ControlId] = SOURCE.ControlId,  
                TARGET.[ReferenceId] = SOURCE.ReferenceId,  
                TARGET.[ReferenceNo] = SOURCE.ReferenceNo,  
                TARGET.[SOWONum] = SOURCE.SOWONum,  
                TARGET.[Notes] = SOURCE.Notes,  
                TARGET.[IsWorkOrder] = SOURCE.IsWorkOrder,  
			    TARGET.[UpdatedBy] = SOURCE.UpdatedBy,  
			    TARGET.[UpdatedDate] = SOURCE.UpdatedDate,  
			    TARGET.[IsActive] = SOURCE.IsActive,  
			    TARGET.[IsDeleted] = SOURCE.IsDeleted        
  
			WHEN NOT MATCHED BY TARGET  
			THEN  
			INSERT([CreditMemoHeaderId],[RMAHeaderId],[InvoiceId],[ItemMasterId],[PartNumber],  
				[PartDescription],[AltPartNumber],[CustPartNumber],[SerialNumber],[Qty],[UnitPrice],[SalesTax], [OtherTax],  
				[PartsRevenue],[LaborRevenue],[MiscRevenue], [FreightRevenue], [RestockingFee], [CogsParts], [CogsLabor], [CogsOverHeadCost], [CogsInventory],
				[Amount],[ReasonId],[Reason],[StocklineId],[StocklineNumber],[ControlNumber],[ControlId],  
				[ReferenceId],[ReferenceNo],[SOWONum],[Notes],[IsWorkOrder],[MasterCompanyId],[CreatedBy],  
				[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[RMADeatilsId],BillingInvoicingItemId)  
			VALUES(SOURCE.CreditMemoHeaderId,SOURCE.RMAHeaderId,SOURCE.InvoiceId,SOURCE.ItemMasterId,SOURCE.PartNumber,  
				SOURCE.PartDescription,SOURCE.AltPartNumber,SOURCE.CustPartNumber,SOURCE.SerialNumber,SOURCE.Qty,SOURCE.UnitPrice, SOURCE.SalesTax, SOURCE.OtherTax ,
				SOURCE.PartsRevenue,SOURCE.LaborRevenue,SOURCE.MiscRevenue,SOURCE.FreightRevenue,SOURCE.RestockingFee,SOURCE.CogsParts,SOURCE.CogsLabor,SOURCE.CogsOverHeadCost,SOURCE.CogsInventory,   
				SOURCE.Amount,SOURCE.ReasonId,SOURCE.Reason,SOURCE.StocklineId,SOURCE.StocklineNumber,SOURCE.ControlNumber,SOURCE.ControlId,  
				SOURCE.ReferenceId,SOURCE.ReferenceNo,SOURCE.SOWONum,SOURCE.Notes,SOURCE.IsWorkOrder,SOURCE.MasterCompanyId,SOURCE.CreatedBy,  
				SOURCE.UpdatedBy,SOURCE.CreatedDate,SOURCE.UpdatedDate,SOURCE.IsActive,SOURCE.IsDeleted,SOURCE.RMADeatilsId,SOURCE.BillingInvoicingItemId);   
			END  

			UPDATE t1 SET t1.Amount = ISNULL(a.Amount,0)
			FROM dbo.CreditMemo t1
			LEFT JOIN (
			SELECT t2.CreditMemoHeaderId,SUM(ISNULL(t2.Amount,0)) Amount 
			FROM dbo.CreditMemoDetails t2 
			GROUP BY t2.CreditMemoHeaderId
			) a on t1.CreditMemoHeaderId = a.CreditMemoHeaderId
			WHERE t1.CreditMemoHeaderId = @CreditMemoHeaderId
 
		END  
		COMMIT  TRANSACTION  
  END TRY    
  BEGIN CATCH        
   IF @@trancount > 0  
   PRINT 'ROLLBACK'  
            ROLLBACK TRAN;  
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertCreditMemoDetails'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL('', '') + ''                  
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