/*************************************************************             
 ** File:   [PROCVendorRFQROChargesAndFreightToRepairOrder]             
 ** Author:  Abhishek Jirawla
 ** Description: This stored procedure is used to convert vendor RFQ RO Charges and Freight to Repair Order Charges and Freight
 ** Purpose:           
 ** Date:   07/25/2024
 ** PARAMETERS: @VendorRFQRepairOrderId bigint,@VendorRFQROPartRecordId bigint,@RepairOrderId bigint,@Opr int  
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    07/25/2024  Abhishek Jirawla   Adding Freight and Charges from VendorRFQRO
-- EXEC [PROCConvertVendorRFQROToRepairOrder] 13,0,0,2,25,1,1  
************************************************************************/  
CREATE     PROCEDURE [dbo].[PROCConvertVendorRFQROChargesAndFreightToRepairOrder]  
@RepairOrderId bigint,    
@VendorRFQRepairOrderId bigint,  
@VendorRFQROPartRecordId bigint,
@RepairOrderPartRecordId bigint,
@Opr int
AS  
BEGIN  
BEGIN TRY
	BEGIN TRANSACTION
	IF @Opr = 1
	BEGIN
		-- Inserting RFQ RO Charges into RO Charges
		INSERT INTO [dbo].[RepairOrderCharges]
		([RepairOrderId],[RepairOrderPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
		,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
		,[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
		,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId])
		SELECT @RepairOrderId,@RepairOrderPartRecordId,[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
		,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
		,[RefNum],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
		,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId]
		FROM [dbo].[VendorRFQROCharges]  WITH(NOLOCK)
		WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND VendorRFQROPartRecordId = @VendorRFQROPartRecordId;
	END

	IF @Opr = 2
	BEGIN
		-- Inserting RFQ RO Freight into RO Freight
		INSERT INTO [dbo].[RepairOrderFreight]
		([RepairOrderId],[RepairOrderPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
		[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
		[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
		[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
		[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LineNum],
		[ManufacturerId],[Manufacturer])
		SELECT @RepairOrderId,@RepairOrderPartRecordId,[ItemMasterId],[PartNumber],[ShipViaId],
		[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
		[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
		[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
		[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LineNum],
		[ManufacturerId],[Manufacturer]
		FROM [dbo].[VendorRFQROFreight]  WITH(NOLOCK)
		WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND VendorRFQROPartRecordId = @VendorRFQROPartRecordId;

	END

	IF @Opr = 3
	BEGIN
	PRINT 'HERE'
	PRINT @VendorRFQRepairOrderId
	PRINT @VendorRFQROPartRecordId
		-- Inserting RFQ RO Charges into RO Charges
		INSERT INTO [dbo].[RepairOrderCharges]
		([RepairOrderId],[RepairOrderPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
		,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
		,[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
		,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId])
		SELECT @RepairOrderId,@RepairOrderPartRecordId,[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
		,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
		,[RefNum],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
		,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId]
		FROM [dbo].[VendorRFQROCharges]  WITH(NOLOCK)
		WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND VendorRFQROPartRecordId = @VendorRFQROPartRecordId;

		-- Inserting RFQ RO Freight into RO Freight
		INSERT INTO [dbo].[RepairOrderFreight]
		([RepairOrderId],[RepairOrderPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
		[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
		[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
		[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
		[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LineNum],
		[ManufacturerId],[Manufacturer])
		SELECT @RepairOrderId,@RepairOrderPartRecordId,[ItemMasterId],[PartNumber],[ShipViaId],
		[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
		[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
		[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
		[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LineNum],
		[ManufacturerId],[Manufacturer]
		FROM [dbo].[VendorRFQROFreight]  WITH(NOLOCK)
		WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId AND VendorRFQROPartRecordId = @VendorRFQROPartRecordId;
	END
  
 COMMIT  TRANSACTION  
 END TRY   
 BEGIN CATCH        
  IF @@trancount > 0  
  PRINT 'ROLLBACK'  
    ROLLBACK TRANSACTION;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'PROCConvertVendorRFQROToRepairOrder'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@VendorRFQRepairOrderId, '') AS varchar(100))  
             + '@Parameter2 = ''' + CAST(ISNULL(@RepairOrderId, '') AS varchar(100))   
             + '@Parameter3 = ''' + CAST(ISNULL(@VendorRFQROPartRecordId, '') AS varchar(100))    
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           = @DatabaseName  
                     , @AdhocComments          = @AdhocComments  
                     , @ProcedureParameters    = @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END