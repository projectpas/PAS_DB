﻿/*************************************************************           
 ** File:   [PROCInsertExchangeQuoteChargesDetails]           
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to Insert/Update ExchangeQuoteCharges table data with name.
 ** Purpose:         
 ** Date:    09-04-2024
 ** PARAMETERS: @TableExchangeQuoteChargesType
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			  Change Description            
 ** --   --------     -------			  --------------------------------          
    1    09-04-2024  Abhishek Jirawla     Created

-- EXEC PROCInsertExchangeQuoteChargesDetails
************************************************************************/
CREATE   PROCEDURE [dbo].[PROCInsertExchangeQuoteChargesDetails](@TableExchangeQuoteChargesType ExchangeQuoteChargesType READONLY)  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF((SELECT COUNT(ExchangeQuoteId) FROM @TableExchangeQuoteChargesType) > 0 )
					BEGIN
						DECLARE @ExchangeQuoteId AS bigint
						SET @ExchangeQuoteId = (SELECT TOP 1 ExchangeQuoteId FROM @TableExchangeQuoteChargesType);
						MERGE dbo.ExchangeQuoteCharges AS TARGET
						USING @TableExchangeQuoteChargesType AS SOURCE ON (TARGET.ExchangeQuoteId = SOURCE.ExchangeQuoteId AND 
					  													     TARGET.ExchangeQuoteChargesId = SOURCE.ExchangeQuoteChargesId)
						WHEN MATCHED 
						THEN UPDATE 
						SET
						--TARGET.[ExchangeQuotePartRecordId] = SOURCE.ExchangeQuotePartRecordId,
						--TARGET.[ItemMasterId] = SOURCE.ItemMasterId,
						TARGET.[ChargesTypeId] = SOURCE.ChargesTypeId,	
						TARGET.[ChargeName] = (SELECT ISNULL(ChargeType,'') FROM [DBO].[Charge] WITH(NOLOCK) WHERE [ChargeId] = ISNULL(SOURCE.ChargesTypeId,0)),
						TARGET.[VendorId] = SOURCE.VendorId,	
						TARGET.[VendorName] = (SELECT ISNULL(VendorName,'') FROM [DBO].[Vendor] WITH(NOLOCK) WHERE [VendorId] = ISNULL(SOURCE.VendorId,0)),
						TARGET.[Quantity] = SOURCE.Quantity,	
						TARGET.[MarkupPercentageId] = SOURCE.MarkupPercentageId,
						TARGET.[MarkupName] = (SELECT ISNULL(PercentValue,0) FROM [DBO].[Percent] WITH(NOLOCK) WHERE [PercentId] = ISNULL(SOURCE.MarkupPercentageId,0)),
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
						--TARGET.[ConditionId] = SOURCE.ConditionId,	
						TARGET.[UpdatedBy] = SOURCE.UpdatedBy,
						TARGET.[UpdatedDate] = SOURCE.UpdatedDate,
						TARGET.[IsActive] = SOURCE.IsActive,
						TARGET.[IsDeleted] = SOURCE.IsDeleted
						--TARGET.[LineNum] = SOURCE.LineNum,
						--TARGET.[PartNumber] = SOURCE.PartNumber,
						--TARGET.[ManufacturerId] = SOURCE.ManufacturerId,
      --                  TARGET.[Manufacturer] = SOURCE.Manufacturer,
                        --TARGET.[UOMId] = SOURCE.UOMId

						WHEN NOT MATCHED BY TARGET
						THEN
							INSERT 
							([ExchangeQuoteId]
							--,[ExchangeQuotePartRecordId]
							,[ChargesTypeId]
							,[ChargeName] 
							,[VendorId]
							,[VendorName]
							,[Quantity]
							,[MarkupPercentageId]
							,[MarkupName]
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
							--,[ItemMasterId]
							--,[ConditionId]
							--,[LineNum]
							--,[PartNumber]
							--,[ManufacturerId]
							--,[Manufacturer]					
							--,[UOMId]					
							)
                     VALUES
							 (SOURCE.ExchangeQuoteId
							 --,SOURCE.ExchangeQuotePartRecordId
							 ,SOURCE.ChargesTypeId
							 ,(SELECT ISNULL(ChargeType,'') FROM [DBO].[Charge] WITH(NOLOCK) WHERE [ChargeId] = ISNULL(SOURCE.ChargesTypeId,0))
							 ,SOURCE.VendorId
							 ,(SELECT ISNULL(VendorName,'') FROM [DBO].[Vendor] WITH(NOLOCK) WHERE [VendorId] = ISNULL(SOURCE.VendorId,0))
							 ,SOURCE.Quantity
							 ,SOURCE.MarkupPercentageId
							 ,(SELECT ISNULL(PercentValue,0) FROM [DBO].[Percent] WITH(NOLOCK) WHERE [PercentId] = ISNULL(SOURCE.MarkupPercentageId,0))
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
							 --,SOURCE.ItemMasterId
							 --,SOURCE.ConditionId
							 --,SOURCE.LineNum
							 --,SOURCE.PartNumber
							 --,SOURCE.ManufacturerId
							 --,SOURCE.Manufacturer							 
							 --,SOURCE.UOMId							 
							 );	
					END

					SELECT top 1 @ExchangeQuoteId = ExchangeQuoteId FROM @TableExchangeQuoteChargesType

					--EXEC UpdateExchangeQuoteChargeNameColumnsWithId @ExchangeQuoteId
					
				END
			COMMIT  TRANSACTION
		END TRY  
		BEGIN CATCH      
			IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
            DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertExchangeQuoteChargesDetails' 
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