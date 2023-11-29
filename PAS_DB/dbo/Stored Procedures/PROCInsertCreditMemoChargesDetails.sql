

CREATE PROCEDURE [dbo].[PROCInsertCreditMemoChargesDetails](@TableCreditMemoChargesType CreditMemoChargesType READONLY)  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF((SELECT COUNT(CreditMemoHeaderId) FROM @TableCreditMemoChargesType) > 0 )
					BEGIN
						DECLARE @CreditMemoHeaderId AS bigint
						SET @CreditMemoHeaderId = (SELECT TOP 1 CreditMemoHeaderId FROM @TableCreditMemoChargesType);
						MERGE dbo.CreditMemoCharges AS TARGET
						USING @TableCreditMemoChargesType AS SOURCE ON (TARGET.CreditMemoHeaderId = SOURCE.CreditMemoHeaderId AND 
					  													     TARGET.CreditMemoChargestId = SOURCE.CreditMemoChargestId) 
						WHEN MATCHED 
						THEN UPDATE 
						SET
						TARGET.[CreditMemoDetailId] = SOURCE.CreditMemoDetailId,
						TARGET.[ItemMasterId] = SOURCE.ItemMasterId,
						TARGET.[ChargesTypeId] = SOURCE.ChargesTypeId,	
						TARGET.[VendorId] = SOURCE.VendorId,	
						TARGET.[Quantity] = SOURCE.Quantity,	
						TARGET.[MarkupPercentageId] = SOURCE.MarkupPercentageId,	
						TARGET.[MarkupFixedPrice] = SOURCE.MarkupFixedPrice,	
						TARGET.[HeaderMarkupId] = SOURCE.HeaderMarkupId,	
						TARGET.[BillingMethodId] = SOURCE.BillingMethodId,	
						TARGET.[BillingRate] = SOURCE.BillingRate,							
						TARGET.[BillingAmount] = SOURCE.BillingAmount,	
						TARGET.[HeaderMarkupPercentageId] = SOURCE.HeaderMarkupPercentageId,						
						TARGET.[Description] = SOURCE.Description,	
						TARGET.[UnitCost] = SOURCE.UnitCost,	
						TARGET.[ExtendedCost] = SOURCE.ExtendedCost,	
						TARGET.[RefNum] = SOURCE.RefNum,	
						TARGET.[ConditionId] = SOURCE.ConditionId,	
						TARGET.[UpdatedBy] = SOURCE.UpdatedBy,
						TARGET.[UpdatedDate] = SOURCE.UpdatedDate,
						TARGET.[IsActive] = SOURCE.IsActive,
						TARGET.[IsDeleted] = SOURCE.IsDeleted						

						WHEN NOT MATCHED BY TARGET
						THEN
							INSERT 
							([CreditMemoHeaderId]
							,[CreditMemoDetailId]
							,[ChargesTypeId]
							,[VendorId]
							,[Quantity]
							,[MarkupPercentageId]
							,[Description]
							,[UnitCost]
							,[ExtendedCost]
							,[MasterCompanyId]
							,[MarkupFixedPrice]
							,[BillingMethodId]
							,[BillingAmount]
							,[BillingRate]
							,[HeaderMarkupId]
							,[RefNum]
							,[CreatedBy]
							,[UpdatedBy]
							,[CreatedDate]
							,[UpdatedDate]
							,[IsActive]
							,[IsDeleted]
							,[HeaderMarkupPercentageId]
							,[ItemMasterId]
							,[ConditionId])
                     VALUES
							 (SOURCE.CreditMemoHeaderId
							 ,SOURCE.CreditMemoDetailId
							 ,SOURCE.ChargesTypeId
							 ,SOURCE.VendorId
							 ,SOURCE.Quantity
							 ,SOURCE.MarkupPercentageId
							 ,SOURCE.Description
							 ,SOURCE.UnitCost
							 ,SOURCE.ExtendedCost
							 ,SOURCE.MasterCompanyId
							 ,SOURCE.MarkupFixedPrice
							 ,SOURCE.BillingMethodId
							 ,SOURCE.BillingAmount
							 ,SOURCE.BillingRate
							 ,SOURCE.HeaderMarkupId
							 ,SOURCE.RefNum
							 ,SOURCE.CreatedBy
							 ,SOURCE.UpdatedBy
							 ,SOURCE.CreatedDate
							 ,SOURCE.UpdatedDate
							 ,SOURCE.IsActive
							 ,SOURCE.IsDeleted
							 ,SOURCE.HeaderMarkupPercentageId
							 ,SOURCE.ItemMasterId
							 ,SOURCE.ConditionId);	
					END
					
					SELECT top 1 @CreditMemoHeaderId = CreditMemoHeaderId FROM @TableCreditMemoChargesType

					EXEC UpdateCreditMemoChargeNameColumnsWithId @CreditMemoHeaderId

				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertCreditMemoChargesDetails' 
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