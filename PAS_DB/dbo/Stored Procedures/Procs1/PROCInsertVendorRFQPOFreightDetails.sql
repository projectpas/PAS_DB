/*************************************************************           
 ** File:   [PROCInsertVendorRFQPOFreightDetails]           
 ** Author: Shrey Chandegara
 ** Description: This stored procedure is used to Insert Data Into VendorRFQPOFreight 
 ** Purpose:         
 ** Date:   04/07/2024     
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/07/2024  Shrey Chandegara     Created
     
************************************************************************/
CREATE    PROCEDURE [dbo].[PROCInsertVendorRFQPOFreightDetails](@TableVendorRFQPOFreightType VendorRFQPOFreightType READONLY)  
AS  
BEGIN  
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED		
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					IF((SELECT COUNT(VendorRFQPurchaseOrderId) FROM @TableVendorRFQPOFreightType) > 0 )
					BEGIN
						DECLARE @VendorRFQPurchaseOrderId AS bigint
						SET @VendorRFQPurchaseOrderId = (SELECT TOP 1 VendorRFQPurchaseOrderId FROM @TableVendorRFQPOFreightType);
						MERGE DBO.[VendorRFQPOFreight] AS TARGET
						USING @TableVendorRFQPOFreightType AS SOURCE ON (TARGET.VendorRFQPurchaseOrderId = SOURCE.VendorRFQPurchaseOrderId AND 
					  													     TARGET.VendorRFQPOFreightId = SOURCE.VendorRFQPOFreightId) 
						WHEN MATCHED 
						THEN UPDATE 
						SET
						TARGET.[VendorRFQPOPartRecordId] = SOURCE.VendorRFQPOPartRecordId,
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
						TARGET.[IsDeleted] = SOURCE.IsDeleted,
						TARGET.[LineNum] = SOURCE.LineNum,
						TARGET.[ManufacturerId] = SOURCE.ManufacturerId,
                        TARGET.[Manufacturer] = SOURCE.Manufacturer						

						WHEN NOT MATCHED BY TARGET
						THEN
							INSERT([VendorRFQPurchaseOrderId],[VendorRFQPOPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
							       [ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
								   [BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
								   [Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
								   [MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LineNum],
								   [ManufacturerId],[Manufacturer])

					         VALUES(SOURCE.VendorRFQPurchaseOrderId,SOURCE.VendorRFQPOPartRecordId,SOURCE.ItemMasterId,SOURCE.PartNumber,SOURCE.ShipViaId,
							       SOURCE.ShipViaName,SOURCE.MarkupPercentageId,SOURCE.MarkupFixedPrice,SOURCE.HeaderMarkupId,SOURCE.BillingMethodId,
								   SOURCE.BillingRate,SOURCE.BillingAmount,SOURCE.HeaderMarkupPercentageId,SOURCE.Weight,SOURCE.UOMId,SOURCE.UOMName,SOURCE.Length,
								   SOURCE.Width,SOURCE.Height,SOURCE.DimensionUOMId,SOURCE.DimensionUOMName,SOURCE.CurrencyId,SOURCE.CurrencyName,SOURCE.Amount,SOURCE.Memo,
								   SOURCE.MasterCompanyId,SOURCE.CreatedBy,SOURCE.UpdatedBy,SOURCE.CreatedDate,SOURCE.UpdatedDate,SOURCE.IsActive,SOURCE.IsDeleted,SOURCE.LineNum,
								   SOURCE.ManufacturerId,SOURCE.Manufacturer);	
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
              , @AdhocComments     VARCHAR(150)    = 'PROCInsertVendorRFQPOFreightDetails' 
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