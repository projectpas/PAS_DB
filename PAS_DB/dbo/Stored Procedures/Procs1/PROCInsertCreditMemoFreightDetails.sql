
CREATE PROCEDURE [dbo].[PROCInsertCreditMemoFreightDetails](@TableCreditMemoFreightType CreditMemoFreightType READONLY)  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF((SELECT COUNT(CreditMemoHeaderId) FROM @TableCreditMemoFreightType) > 0 )
					BEGIN
						DECLARE @CreditMemoHeaderId AS bigint
						SET @CreditMemoHeaderId = (SELECT TOP 1 CreditMemoHeaderId FROM @TableCreditMemoFreightType);
						MERGE dbo.CreditMemoFreight AS TARGET
						USING @TableCreditMemoFreightType AS SOURCE ON (TARGET.CreditMemoHeaderId = SOURCE.CreditMemoHeaderId AND 
					  													     TARGET.CreditMemoFreightId = SOURCE.CreditMemoFreightId) 
						WHEN MATCHED 
						THEN UPDATE 
						SET
						TARGET.[CreditMemoDetailId] = SOURCE.CreditMemoDetailId,
						TARGET.[ItemMasterId] = SOURCE.ItemMasterId,
						TARGET.[PartNumber] = SOURCE.PartNumber,	
						TARGET.[ShipViaId] = SOURCE.ShipViaId,	
						TARGET.[ShipViaName] = SOURCE.ShipViaName,	
						TARGET.[MarkupPercentageId] = SOURCE.MarkupPercentageId,	
						TARGET.[MarkupFixedPrice] = SOURCE.MarkupFixedPrice,	
						TARGET.[HeaderMarkupId] = SOURCE.HeaderMarkupId,	
						TARGET.[BillingMethodId] = SOURCE.BillingMethodId,	
						TARGET.[BillingRate] = SOURCE.BillingRate,							
						TARGET.[BillingAmount] = SOURCE.BillingAmount,	
						TARGET.[HeaderMarkupPercentageId] = SOURCE.HeaderMarkupPercentageId,						
						TARGET.[Weight] = SOURCE.Weight,	
						TARGET.[UOMId] = SOURCE.UOMId,	
						TARGET.[UOMName] = SOURCE.UOMName,	
						TARGET.[Length] = SOURCE.Length,	
						TARGET.[Width] = SOURCE.Width,	
						TARGET.[Height] = SOURCE.Height,
						TARGET.[DimensionUOMId] = SOURCE.DimensionUOMId,	
						TARGET.[DimensionUOMName] = SOURCE.DimensionUOMName,							
						TARGET.[CurrencyId] = SOURCE.CurrencyId,	
						TARGET.[CurrencyName] = SOURCE.CurrencyName,	
						TARGET.[Amount] = SOURCE.Amount,	
						TARGET.[Memo] = SOURCE.Memo,												
						TARGET.[UpdatedBy] = SOURCE.UpdatedBy,
						TARGET.[UpdatedDate] = SOURCE.UpdatedDate,
						TARGET.[IsActive] = SOURCE.IsActive,
						TARGET.[IsDeleted] = SOURCE.IsDeleted						

						WHEN NOT MATCHED BY TARGET
						THEN
							INSERT([CreditMemoHeaderId],[CreditMemoDetailId],[ItemMasterId],[PartNumber],[ShipViaId],
							       [ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
								   [BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
								   [Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
								   [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted])

					         VALUES(SOURCE.CreditMemoHeaderId,SOURCE.CreditMemoDetailId,SOURCE.ItemMasterId,SOURCE.PartNumber,SOURCE.ShipViaId,
							       SOURCE.ShipViaName,SOURCE.MarkupPercentageId,SOURCE.MarkupFixedPrice,SOURCE.HeaderMarkupId,SOURCE.BillingMethodId,
								   SOURCE.BillingRate,SOURCE.BillingAmount,SOURCE.HeaderMarkupPercentageId,SOURCE.Weight,SOURCE.UOMId,SOURCE.UOMName,SOURCE.Length,
								   SOURCE.Width,SOURCE.Height,SOURCE.DimensionUOMId,SOURCE.DimensionUOMName,SOURCE.CurrencyId,SOURCE.CurrencyName,SOURCE.Amount,SOURCE.Memo,
								   SOURCE.MasterCompanyId,SOURCE.CreatedBy,SOURCE.UpdatedBy,SOURCE.CreatedDate,SOURCE.UpdatedDate,SOURCE.IsActive,SOURCE.IsDeleted);	
					END
					
				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertCreditMemoFreightDetails' 
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