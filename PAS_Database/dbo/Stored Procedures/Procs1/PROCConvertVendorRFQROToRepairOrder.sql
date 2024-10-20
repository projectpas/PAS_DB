﻿/*************************************************************             
 ** File:   [PROCConvertVendorRFQROToRepairOrder]             
 ** Author:  Moin Bloch  
 ** Description: This stored procedure is used to convert vendor RFQ RO to Repair Order    
 ** Purpose:           
 ** Date:   04/01/2022  
 ** PARAMETERS: @VendorRFQRepairOrderId bigint,@VendorRFQROPartRecordId bigint,@RepairOrderId bigint,@MasterCompanyId int,@CodeTypeId int,@Opr int  
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    05/01/2022  Moin Bloch			Created  
	2    05/22/2023  Satish Gohil		Remove Automatic (-)
	3    07/19/2024  Abhishek Jirawla   Adding Freight and Charges from VendorRFQRO
	4    09/12/2024  AMIT GHEDIYA		Adding FunctionalCurrencyId,ReportCurrencyId and ForeignExchangeRate from VendorRFQRO
-- EXEC [PROCConvertVendorRFQROToRepairOrder] 13,0,0,2,25,1,1  
************************************************************************/  
CREATE   PROCEDURE [dbo].[PROCConvertVendorRFQROToRepairOrder]  
@VendorRFQRepairOrderId bigint,  
@VendorRFQROPartRecordId bigint,  
@RepairOrderId bigint,  
@MasterCompanyId int,  
@CodeTypeId int,  
@Opr int,  
@Result int OUTPUT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
 DECLARE @CurrentNummber bigint;  
 DECLARE @CodePrefix VARCHAR(50);  
 DECLARE @CodeSufix VARCHAR(50);   
 DECLARE @RepairOrderNumber VARCHAR(250);  
 DECLARE @IsEnforceApproval bit;  
 DECLARE @RONumber VARCHAR(250);  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  
  DECLARE @MCID INT=0;  
  DECLARE @MSID BIGINT=0;  
  DECLARE @CreateBy VARCHAR(100)='';  
  DECLARE @UpdateBy VARCHAR(100)='';  
  DECLARE @RID BIGINT=0;  
	IF(@Opr = 1)  
	BEGIN  
		IF NOT EXISTS (SELECT 1 FROM dbo.RepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId)  
		BEGIN     
			SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM dbo.CodePrefixes WITH(NOLOCK)  
			WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;  
  
			SELECT TOP 1 @IsEnforceApproval = [IsEnforceApproval] FROM dbo.RepairOrderSettingMaster WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;  
       
			IF(@CurrentNummber!='' OR @CurrentNummber!=NULL)  
			BEGIN  
				SET @RepairOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));  
				INSERT INTO [dbo].[RepairOrder]([RepairOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],  
					 [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],  
					 [RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],  
					 [RoMemo],[Notes],[ApproverId],[ApprovedBy],[ApprovedDate],[ManagementStructureId],[Level1],[Level2],  
					 [Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],  
					 [IsDeleted],[IsEnforce],[PDFPath],[VendorRFQRepairOrderId], [FreightBilingMethodId], [TotalFreight], [ChargesBilingMethodId], [TotalCharges],
					 [FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate])  
					SELECT @RepairOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],  
					 [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],  
					 [RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],  
					 [Memo],[Notes],NULL,NULL,NULL,[ManagementStructureId],[Level1],[Level2],  
					 [Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,  
					 0,@IsEnforceApproval,NULL,@VendorRFQRepairOrderId, [FreightBilingMethodId], [TotalFreight], [ChargesBilingMethodId], [TotalCharges],
					 [FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate]
					 FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;  
        
				UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;  
      
				
				SET @RID=IDENT_CURRENT('RepairOrder');  
				SELECT @MSID=[ManagementStructureId],@MCID=[MasterCompanyId],  
					@CreateBy=[CreatedBy],@UpdateBy=[UpdatedBy]  
				FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId;  

				EXEC [DBO].[PROCAddROMSData] @RID,@MSID,@MCID,@CreateBy,@UpdateBy,24,1,0  
  
				IF EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQRepairOrderId AND ModuleId = 32)  
				BEGIN  
					INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],  
					   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],  
					   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],  
					   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])  
					  SELECT IDENT_CURRENT('RepairOrder'),14,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],  
					   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],  
					   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],  
					   [UpdatedBy],GETDATE(),GETDATE(),1,0,[IsPrimary]  
					 FROM [dbo].[AllAddress] WHERE [ReffranceId] = @VendorRFQRepairOrderId AND ModuleId = 32;  
  
					INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],  
					   [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,  
					   [IsActive] ,[IsDeleted])  
					 SELECT IDENT_CURRENT('RepairOrder'),14,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],  
					  [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,GETDATE() ,GETDATE() ,  
					  1,0   
					FROM [dbo].[AllShipVia] WHERE [ReferenceId] = @VendorRFQRepairOrderId AND ModuleId = 32;  
				 END    

				-- -- Inserting RFQ RO Charges into RO Charges
				--INSERT INTO [dbo].[RepairOrderCharges]
				--([RepairOrderId],[RepairOrderPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
				--,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
				--,[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
				--,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId])
				--SELECT IDENT_CURRENT('RepairOrder'),[VendorRFQROPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
				--,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
				--,[RefNum],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
				--,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId]
				--FROM [dbo].[VendorRFQROCharges] WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

				---- Inserting RFQ RO Freight into RO Freight
				--INSERT INTO [dbo].[RepairOrderFreight]
				--([RepairOrderId],[RepairOrderPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
				--[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
				--[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
				--[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
				--[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LineNum],
				--[ManufacturerId],[Manufacturer])
				--SELECT IDENT_CURRENT('RepairOrder'),[VendorRFQROPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
				--[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
				--[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
				--[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
				--[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LineNum],
				--[ManufacturerId],[Manufacturer]
				--FROM [dbo].[VendorRFQROFreight] WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

				SELECT @Result = IDENT_CURRENT('RepairOrder');

			END  
			ELSE  
			BEGIN       
				SELECT @Result = 0;  
			END 
			
		END  
		ELSE  
		BEGIN     
		SELECT @Result = -1;  
		END  
	END   
	IF(@Opr = 2)  
	BEGIN  
		IF NOT EXISTS (SELECT 1 FROM dbo.RepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId)  
		BEGIN     
			SELECT @CurrentNummber = [CurrentNummber],@CodePrefix = [CodePrefix],@CodeSufix = [CodeSufix] FROM dbo.CodePrefixes WITH(NOLOCK)  
			WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;  
  
			SELECT TOP 1 @IsEnforceApproval = [IsEnforceApproval] FROM dbo.RepairOrderSettingMaster WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId;  
       
			IF(@CurrentNummber!='' OR @CurrentNummber!=NULL)  
			BEGIN  
				SET @RepairOrderNumber = (SELECT * FROM dbo.udfGenerateCodeNumberWithOutDash(CAST(@CurrentNummber AS BIGINT) + 1, @CodePrefix, @CodeSufix));  
				 INSERT INTO [dbo].[RepairOrder]([RepairOrderNumber],[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],  
						 [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],  
						 [RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],  
						 [RoMemo],[Notes],[ApproverId],[ApprovedBy],[ApprovedDate],[ManagementStructureId],[Level1],[Level2],  
						 [Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],  
						 [IsDeleted],[IsEnforce],[PDFPath],[VendorRFQRepairOrderId], [FreightBilingMethodId], [TotalFreight], [ChargesBilingMethodId], [TotalCharges],
						 [FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate])  
						SELECT @RepairOrderNumber,[OpenDate],[ClosedDate],[NeedByDate],[PriorityId],[Priority],[VendorId],[VendorName],  
						 [VendorCode],[VendorContactId],[VendorContact],[VendorContactPhone],[CreditTermsId],[Terms],[CreditLimit],  
						 [RequisitionerId],[Requisitioner],[StatusId],[Status],[StatusChangeDate],[Resale],[DeferredReceiver],  
						 [Memo],[Notes],NULL,NULL,NULL,[ManagementStructureId],[Level1],[Level2],  
						 [Level3],[Level4],[MasterCompanyId],[CreatedBy],[UpdatedBy],GETDATE(),GETDATE(),1,  
						 0,@IsEnforceApproval,NULL,@VendorRFQRepairOrderId  , [FreightBilingMethodId], [TotalFreight], [ChargesBilingMethodId], [TotalCharges],
						 [FunctionalCurrencyId],[ReportCurrencyId],[ForeignExchangeRate]
						 FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId;  
        
				UPDATE dbo.CodePrefixes SET CurrentNummber = CAST(@CurrentNummber AS BIGINT) + 1 WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;  
      
        
				SET @RID=IDENT_CURRENT('RepairOrder');  

				SELECT @MSID=[ManagementStructureId],@MCID=[MasterCompanyId],  
					@CreateBy=[CreatedBy],@UpdateBy=[UpdatedBy]  
				FROM dbo.VendorRFQRepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId]=@VendorRFQRepairOrderId;  

				EXEC [DBO].[PROCAddROMSData] @RID,@MSID,@MCID,@CreateBy,@UpdateBy,24,1,0  


				IF EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQRepairOrderId AND ModuleId = 32)  
				BEGIN  
					INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],  
					   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],  
					   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],  
					   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])  
					  SELECT IDENT_CURRENT('RepairOrder'),14,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],  
					   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],  
					   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],  
					   [UpdatedBy],GETDATE(),GETDATE(),1,0,[IsPrimary]  
					 FROM [dbo].[AllAddress] WHERE [ReffranceId] = @VendorRFQRepairOrderId AND ModuleId = 32;  
  
					 INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],  
						   [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,  
						   [IsActive] ,[IsDeleted])  
						 SELECT IDENT_CURRENT('RepairOrder'),14,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],  
						  [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,GETDATE() ,GETDATE() ,  
						  1,0   
						FROM [dbo].[AllShipVia] WHERE [ReferenceId] = @VendorRFQRepairOrderId AND ModuleId = 32;  
  
				END    

				-- -- Inserting RFQ RO Charges into RO Charges
				--INSERT INTO [dbo].[RepairOrderCharges]
				--([RepairOrderId],[RepairOrderPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
				--,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
				--,[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
				--,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId])
				--SELECT IDENT_CURRENT('RepairOrder'),[VendorRFQROPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
				--,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
				--,[RefNum],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
				--,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId]
				--FROM [dbo].[VendorRFQROCharges] WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

				---- Inserting RFQ RO Freight into RO Freight
				--INSERT INTO [dbo].[RepairOrderFreight]
				--([RepairOrderId],[RepairOrderPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
				--[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
				--[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
				--[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
				--[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LineNum],
				--[ManufacturerId],[Manufacturer])
				--SELECT IDENT_CURRENT('RepairOrder'),[VendorRFQROPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
				--[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
				--[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
				--[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
				--[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LineNum],
				--[ManufacturerId],[Manufacturer]
				--FROM [dbo].[VendorRFQROFreight] WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId;

				SELECT @Result = IDENT_CURRENT('RepairOrder');          
			END  
			ELSE  
			BEGIN       
			 SELECT @Result = 0;  
			END  
		END  
		ELSE  
		BEGIN   
  
			SELECT @Result = (SELECT RepairOrderId FROM dbo.RepairOrder WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId);    
       
			IF EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @VendorRFQRepairOrderId AND ModuleId = 32)  
			BEGIN  
				IF NOT EXISTS (SELECT 1 FROM dbo.AllAddress WITH(NOLOCK) WHERE [ReffranceId] = @Result AND ModuleId = 14)  
				BEGIN  
					INSERT INTO [dbo].[AllAddress]([ReffranceId],[ModuleId],[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],  
					   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],  
					   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],  
					   [UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[IsPrimary])  
					  SELECT @Result,14,[UserType],[UserTypeName],[UserId],[UserName],[SiteId],[SiteName],  
					   [AddressId],[IsModuleOnly],[IsShippingAdd],[ShippingAccountNo],[Memo],[ContactId],[ContactName],[ContactPhoneNo],  
					   [Line1],[Line2],[Line3],[City],[StateOrProvince],[PostalCode],[CountryId],[Country],[MasterCompanyId],[CreatedBy],  
					   [UpdatedBy],GETDATE(),GETDATE(),1,0,[IsPrimary]  
					 FROM [dbo].[AllAddress] where [ReffranceId] = @VendorRFQRepairOrderId AND ModuleId = 32;  
				END  
			END  
  
			IF EXISTS (SELECT 1 FROM dbo.AllShipVia WITH(NOLOCK) WHERE [ReferenceId] = @VendorRFQRepairOrderId AND ModuleId = 32)  
			BEGIN  
				IF NOT EXISTS (SELECT 1 FROM dbo.AllShipVia WITH(NOLOCK) WHERE [ReferenceId] = @Result AND ModuleId = 14)  
				BEGIN  
					INSERT INTO [dbo].[AllShipVia]([ReferenceId],[ModuleId],[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],  
					   [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,[CreatedDate] ,[UpdatedDate] ,  
					   [IsActive] ,[IsDeleted])  
					 SELECT @Result,14,[UserType],[ShipViaId],[ShippingCost],[HandlingCost],[IsModuleShipVia],  
					  [ShippingAccountNo],[ShipVia],[ShippingViaId],[MasterCompanyId],[CreatedBy],[UpdatedBy] ,GETDATE() ,GETDATE(),  
					  1,0   
					FROM [dbo].[AllShipVia] WHERE [ReferenceId] = @VendorRFQRepairOrderId AND ModuleId = 32;  
				END  
			END   
			
			--IF EXISTS (SELECT 1 FROM dbo.[VendorRFQROCharges] WITH(NOLOCK) WHERE [VendorRFQRepairOrderId] = @VendorRFQRepairOrderId)  
			--BEGIN  
			--	IF NOT EXISTS (SELECT 1 FROM dbo.[RepairOrderCharges] WITH(NOLOCK) WHERE [RepairOrderId] = @Result)  
			--	BEGIN  
			--		-- Inserting RFQ RO Charges into RO Charges
			--		INSERT INTO [dbo].[RepairOrderCharges]
			--		([RepairOrderId],[RepairOrderPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
			--		,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
			--		,[RefNum],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
			--		,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId])
			--		SELECT @Result,[VendorRFQROPartRecordId],[ChargesTypeId],[VendorId],[Quantity],[MarkupPercentageId],[Description]
			--		,[UnitCost],[ExtendedCost],[MasterCompanyId],[MarkupFixedPrice],[BillingMethodId],[BillingAmount],[BillingRate],[HeaderMarkupId]
			--		,[RefNum],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[HeaderMarkupPercentageId],[ItemMasterId]
			--		,[ConditionId],[LineNum],[PartNumber],[ManufacturerId],[Manufacturer],[UOMId]
			--		FROM [dbo].[VendorRFQROCharges] WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId;
			--	END
			--END

			--IF EXISTS (SELECT 1 FROM dbo.[VendorRFQROFreight] WITH(NOLOCK) WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId)  
			--BEGIN  
			--	IF NOT EXISTS (SELECT 1 FROM dbo.[RepairOrderFreight] WITH(NOLOCK) WHERE [RepairOrderId] = @Result)  
			--	BEGIN 
			--		-- Inserting RFQ RO Freight into RO Freight
			--		INSERT INTO [dbo].[RepairOrderFreight]
			--		([RepairOrderId],[RepairOrderPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
			--		[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
			--		[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
			--		[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
			--		[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[LineNum],
			--		[ManufacturerId],[Manufacturer])
			--		SELECT @Result,[VendorRFQROPartRecordId],[ItemMasterId],[PartNumber],[ShipViaId],
			--		[ShipViaName],[MarkupPercentageId],[MarkupFixedPrice],[HeaderMarkupId],[BillingMethodId],
			--		[BillingRate],[BillingAmount],[HeaderMarkupPercentageId],[Weight],[UOMId],[UOMName],[Length],
			--		[Width],[Height],[DimensionUOMId],[DimensionUOMName],[CurrencyId],[CurrencyName],[Amount],[Memo],
			--		[MasterCompanyId],[CreatedBy],[UpdatedBy],GETUTCDATE(),GETUTCDATE(),[IsActive],[IsDeleted],[LineNum],
			--		[ManufacturerId],[Manufacturer]
			--		FROM [dbo].[VendorRFQROFreight] WHERE VendorRFQRepairOrderId = @VendorRFQRepairOrderId;
			--	END
			--END

      
		END  
	END  
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
             + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))   
             + '@Parameter3 = ''' + CAST(ISNULL(@CodeTypeId, '') AS varchar(100))    
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