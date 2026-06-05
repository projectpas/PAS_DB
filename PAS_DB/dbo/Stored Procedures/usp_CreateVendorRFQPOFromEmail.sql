/*************************************************************           
 ** File:   [usp_CreateVendorRFQPOFromEmail]           
 ** Author:   Vishal Suthar
 ** Description: Create Vendor RFQ PO from Email for A2Z
 ** Purpose:          
 ** Date:   02-June-2026     
          
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date			Author			Change Description            
 ** --   --------		-------			--------------------------------          
    1    02-June-2026   Vishal Suthar   Created

**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_CreateVendorRFQPOFromEmail]
    @IntegrationEmailID   BIGINT,
    @MasterCompanyId      INT,
    @EmployeeId           BIGINT,
    @VendorName           NVARCHAR(500),
    @VendorEmail          NVARCHAR(200) = NULL,
    @VendorPhone          NVARCHAR(100) = NULL,
    @Address1             NVARCHAR(500) = NULL,
    @Address2             NVARCHAR(500) = NULL,
    @City                 NVARCHAR(200) = NULL,
    @StateProvince        NVARCHAR(200) = NULL,
    @PostalCode           NVARCHAR(50)  = NULL,
    @Country              NVARCHAR(200) = NULL,
    @EmailSubject         NVARCHAR(500) = NULL,
    @tbl_EmailParts       [dbo].[tbl_EmailVendorRFQPartType] READONLY
AS
BEGIN
    SET NOCOUNT ON;
	BEGIN TRY
		BEGIN TRANSACTION
			-- Replace the DECLARE block -- add @ContactId:
			DECLARE
				@VendorId                     BIGINT = NULL,
				@VendorContactId              BIGINT        = NULL,
				@ContactId                    BIGINT,           -- NEW
				@PriorityId                   BIGINT,
				@PriorityName                 NVARCHAR(100),
				@ManagementStructureId        BIGINT,
				@VendorRFQPurchaseOrderId     BIGINT,
				@VendorRFQPurchaseOrderNumber NVARCHAR(100),
				@CurrentNumber                BIGINT,
				@CodePrefixVal                NVARCHAR(50),
				@CodeSuffix                   NVARCHAR(50),
				@PaddedNum                    NVARCHAR(20),
				@AddressId                    BIGINT,
				@CountryId                    INT,
				@CreatedBy                    NVARCHAR(100) = 'ADMIN ADMIN',
				@Now                          DATETIME2     = GETUTCDATE(),
				@NeedByDate                   DATETIME2     = DATEADD(DAY, 30, GETUTCDATE());

			-- 1. Lookup vendor by email first, then by name
			SELECT TOP 1 @VendorId = VendorId
			FROM dbo.Vendor WITH (NOLOCK)
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
			  AND (
					(@VendorEmail IS NOT NULL AND VendorEmail = @VendorEmail)
				 OR (@VendorName  IS NOT NULL AND VendorName LIKE '%' + @VendorName + '%')
				  )
			ORDER BY CASE WHEN VendorEmail = @VendorEmail THEN 0 ELSE 1 END;

			DECLARE @VendorCode VARCHAR(100) = NULL;

			DECLARE @DefaultEmployeeId BIGINT;

			SELECT @DefaultEmployeeId = EmployeeId FROM dbo.Employee
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
			AND FirstName = 'ADMIN';

			DECLARE @DefaultCurrencyId BIGINT;

			SELECT TOP 1 @DefaultCurrencyId = CurrencyId FROM dbo.Currency
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			-- 2. Create vendor if not found
			IF @VendorId IS NULL
			BEGIN
				IF @VendorCode IS NULL OR @VendorCode = 'VEN' OR @VendorCode = 'Creating'
				BEGIN
					DECLARE @Number BIGINT = 0;
					DECLARE @CodePrefixId BIGINT = 0;
					DECLARE @CodePrefix VARCHAR(50) = '', @CodeSufix VARCHAR(50) = '';

					SELECT 
						@Number = ISNULL(CP.CurrentNummber, CP.StartsFrom), 
						@CodePrefixId = CP.CodePrefixId,
						@CodePrefix = CP.CodePrefix,
						@CodeSufix = CP.CodeSufix
					FROM dbo.CodeTypes CT WITH (NOLOCK)
					INNER JOIN dbo.CodePrefixes CP WITH (NOLOCK) ON CT.CodeTypeId = CP.CodeTypeId
					WHERE 
						CT.IsActive = 1 AND CT.IsDeleted = 0 AND
						CP.IsActive = 1 AND CP.IsDeleted = 0 AND
						CP.MasterCompanyId = @MasterCompanyId AND
						CT.CodeType = 'Vendor';

					SET @VendorCode = (SELECT * FROM [DBO].[udfGenerateCodeNumberWithOutDash](CAST(@Number AS BIGINT) + 1, @codePrefix,@codeSufix));
					
					UPDATE CodePrefixes
					SET CurrentNummber = @Number + 1
					WHERE CodePrefixId = @CodePrefixId;
				END

				SELECT TOP 1 @CountryId = countries_id
				FROM dbo.Countries WITH (NOLOCK)
				WHERE countries_name = @Country AND MasterCompanyId = @MasterCompanyId;

				IF (ISNULL(@CountryId, 0) = 0)
				BEGIN
					SELECT TOP 1 @CountryId = countries_id
					FROM dbo.Countries WITH (NOLOCK)
					WHERE UPPER(countries_name) = 'UNITED STATES' AND MasterCompanyId = @MasterCompanyId;
				END

				-- Create Address
				INSERT INTO dbo.Address
				(
					Line1, Line2, City, StateOrProvince,
					PostalCode, CountryId,
					MasterCompanyId,
					CreatedBy, UpdatedBy,
					CreatedDate, UpdatedDate,
					IsActive, IsDeleted
				)
				VALUES
				(
					ISNULL(@Address1, 'N/A'), ISNULL(@Address2, 'N/A'), ISNULL(@City, 'N/A'), ISNULL(@StateProvince, 'N/A'),
					ISNULL(@PostalCode, 'N/A'), @CountryId,
					@MasterCompanyId,
					@CreatedBy, @CreatedBy,
					@Now, @Now,
					1, 0
				);

				SET @AddressId = SCOPE_IDENTITY();

				-- Create Vendor
				INSERT INTO dbo.Vendor
				(
					VendorName,
					VendorCode,
					VendorEmail,
					VendorPhone,
					VendorTypeId,
					AddressId,
					MasterCompanyId,
					CreatedBy,
					UpdatedBy,
					CreatedDate,
					UpdatedDate,
					IsActive,
					IsDeleted,
					Is1099Required
				)
				VALUES
				(
					@VendorName,
					@VendorCode,
					@VendorEmail,
					@VendorPhone,
					2,
					@AddressId,
					@MasterCompanyId,
					@CreatedBy,
					@CreatedBy,
					@Now,
					@Now,
					1,
					0,
					0
				);

				SET @VendorId = SCOPE_IDENTITY();
			END
			ELSE
			BEGIN
				SELECT TOP 1 @VendorContactId = VendorContactId
				FROM dbo.VendorContact WITH (NOLOCK)
				WHERE VendorId = @VendorId AND IsActive = 1 AND IsDeleted = 0;
			END

			-- Create Contact + VendorContact if still no contact (new vendor OR existing vendor with no contact)
			IF @VendorContactId IS NULL
			BEGIN
				DECLARE
					@ContactFirstName NVARCHAR(100),
					@ContactLastName  NVARCHAR(30);

				-- Split VendorName into FirstName / LastName
				IF CHARINDEX(' ', LTRIM(RTRIM(@VendorName))) > 0
				BEGIN
					SET @ContactFirstName = LEFT(LTRIM(RTRIM(@VendorName)),
												CHARINDEX(' ', LTRIM(RTRIM(@VendorName))) - 1);
					SET @ContactLastName  = LEFT(
												SUBSTRING(LTRIM(RTRIM(@VendorName)),
													CHARINDEX(' ', LTRIM(RTRIM(@VendorName))) + 1,
													LEN(@VendorName)),
												30);
				END
				ELSE
				BEGIN
					SET @ContactFirstName = LEFT(LTRIM(RTRIM(@VendorName)), 100);
					SET @ContactLastName  = 'N/A';
				END

				INSERT INTO dbo.Contact
					(FirstName, LastName, WorkPhone, Email,
					 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
					 IsActive, IsDeleted)
				VALUES
					(@ContactFirstName, @ContactLastName, @VendorPhone, @VendorEmail,
					 @MasterCompanyId, @CreatedBy, @CreatedBy, @Now, @Now,
					 1, 0);

				SET @ContactId = SCOPE_IDENTITY();

				INSERT INTO dbo.VendorContact
					(VendorId, ContactId, Tag, IsDefaultContact,
					 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
					 IsActive, IsDeleted)
				VALUES
					(@VendorId, @ContactId, 'Primary', 1,
					 @MasterCompanyId, @CreatedBy, @CreatedBy, @Now, @Now,
					 1, 0);

				SET @VendorContactId = SCOPE_IDENTITY();
			END

			-- 3. Get default priority
			SELECT TOP 1 @PriorityId = PriorityId, @PriorityName = Description
			FROM dbo.[Priority] WITH (NOLOCK)
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0
			ORDER BY PriorityId;

			IF @PriorityId IS NULL RETURN;

			-- 4. Get default management structure
			SELECT TOP 1 @ManagementStructureId = EntityStructureId
			FROM dbo.EntityStructureSetup WITH (NOLOCK)
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			IF @ManagementStructureId IS NULL RETURN;

			-- 5. Get and increment CodePrefix (CodeTypeId = 61 = VendorRFQPurchaseOrder)
			SELECT @CurrentNumber = CurrentNummber, @CodePrefixVal = CodePrefix, @CodeSuffix = CodeSufix
			FROM dbo.CodePrefixes WITH (NOLOCK)
			WHERE CodeTypeId = 61 AND MasterCompanyId = @MasterCompanyId;

			IF @CurrentNumber IS NULL RETURN;

			SET @CurrentNumber = @CurrentNumber + 1;

			UPDATE dbo.CodePrefixes
			SET CurrentNummber = @CurrentNumber
			WHERE CodeTypeId = 61 AND MasterCompanyId = @MasterCompanyId;

			-- Replicate PASCommon.GenerateCodeNumber (6-digit zero-padded)
			SET @PaddedNum = RIGHT('000000' + CAST(@CurrentNumber AS NVARCHAR(20)),
								   CASE WHEN LEN(CAST(@CurrentNumber AS NVARCHAR)) < 6 THEN 6
										ELSE LEN(CAST(@CurrentNumber AS NVARCHAR)) END);

			SET @VendorRFQPurchaseOrderNumber =
				CASE
					WHEN ISNULL(@CodePrefixVal,'') <> '' AND ISNULL(@CodeSuffix,'') <> ''
						THEN @CodePrefixVal + '-' + @PaddedNum + '-' + @CodeSuffix
					WHEN ISNULL(@CodePrefixVal,'') = '' AND ISNULL(@CodeSuffix,'') <> ''
						THEN @PaddedNum + '-' + @CodeSuffix
					WHEN ISNULL(@CodePrefixVal,'') <> '' AND ISNULL(@CodeSuffix,'') = ''
						THEN @CodePrefixVal + '-' + @PaddedNum
					ELSE @PaddedNum
				END;

			-- 6. Create VendorRFQPurchaseOrder header
			INSERT INTO dbo.VendorRFQPurchaseOrder
				(VendorRFQPurchaseOrderNumber, VendorId, VendorName, VendorCode,
				 VendorContactId, PriorityId, Priority, RequestedBy,
				 StatusId, OpenDate, NeedByDate, CreditLimit,
				 ManagementStructureId, Notes, MasterCompanyId,
				 CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
				 IsActive, IsDeleted, Resale, DeferredReceiver, IsFromBulkPO, SourceBy,
				 FunctionalCurrencyId, ReportCurrencyId, ForeignExchangeRate)
			SELECT
				@VendorRFQPurchaseOrderNumber, @VendorId, v.VendorName, v.VendorCode,
				@VendorContactId, @PriorityId, @PriorityName, CASE WHEN ISNULL(@EmployeeId, 0) = 0 THEN @DefaultEmployeeId ELSE @EmployeeId END,
				1 /*Open*/, @Now, @NeedByDate, ISNULL(v.CreditLimit, 0),
				@ManagementStructureId, 'Auto-created from email', @MasterCompanyId,
				@CreatedBy, @CreatedBy, @Now, @Now,
				1, 0, 0, 0, 0, 'Email',
				@DefaultCurrencyId, @DefaultCurrencyId, 1
			FROM dbo.Vendor v
			WHERE v.VendorId = @VendorId;

			SET @VendorRFQPurchaseOrderId = SCOPE_IDENTITY();

			 -- 6a. Save header management structure details (ModuleId = 20 = VendorRFQPOHeader)
			DECLARE @MSHeaderId BIGINT;
			EXEC dbo.[PROCAddPOMSData]
				@VendorRFQPurchaseOrderId,
				@ManagementStructureId,
				@MasterCompanyId,
				@CreatedBy,
				@CreatedBy,
				20,       -- VendorRFQPOHeader
				1,        -- Opr = 1 (insert)
				@MSHeaderId OUTPUT;

			DECLARE @TemplateItemMasterId BIGINT;
			DECLARE @NewItemMasterId BIGINT;

			SELECT TOP 1 @TemplateItemMasterId = ItemMasterId
			FROM dbo.ItemMaster WITH (NOLOCK)
			WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND IsDeleted = 0;

			INSERT INTO dbo.ItemMaster
			(
				ItemTypeId,
				ItemGroupId,
				ItemClassificationId,
				IsHazardousMaterial,
				IsExpirationDateAvailable,
				IsReceivedDateAvailable,
				DaysReceived,
				IsManufacturingDateAvailable,
				ManufacturingDays,
				IsTagDateAvailable,
				TagDays,
				IsOpenDateAvailable,
				OpenDays,
				IsShippedDateAvailable,
				ShippedDays,
				IsOtherDateAvailable,
				OtherDays,
				IsDER,
				IsSchematic,
				OverhaulHours,
				RPHours,
				TestHours,
				RFQTracking,
				ManufacturerId,
				GLAccountId,
				PurchaseUnitOfMeasureId,
				StockUnitOfMeasureId,
				ConsumeUnitOfMeasureId,
				LeadTimeDays,
				ReorderPoint,
				ReorderQuantiy,
				MinimumOrderQuantity,
				PurchaseCurrencyId,
				SalesCurrencyId,
				MasterCompanyId,
				CreatedBy,
				UpdatedBy,
				CreatedDate,
				UpdatedDate,
				TurnTimeOverhaulHours,
				TurnTimeRepairHours,
				isTimeLife,
				isSerialized,
				ShelfLife,
				StockLevel,
				ShelfLifeAvailable,
				mfgHours,
				IsPma,
				turnTimeMfg,
				turnTimeBenchTest,
				SiteId,
				ItemMasterAssetTypeId,
				IsHotItem,
				IsAcquiredMethodBuy,
				IsOEM,
				MTBUR,
				NE,
				NS,
				OH,
				REP,
				SVC,
				PartNumber,
				PartDescription,
				IsActive,
				IsDeleted,
				InventoryGLSettingId,
				GoodsReceivedNotInvoicesGLAccId,
				WorkInProgressGLAccId,
				InventoryToBillGLAccId,
				FinishedGoodsGLAccId,
				InventoryExchAgreementGLAccId,
				InventoryReserveGLAccId,
				COGS_WorkOrderGLAccId,
				COGS_SalesOrderGLAccId,
				COGS_QtyVarianceGLAccId,
				COGS_UnitCostVarianceGLAccId,
				RevenueMroGLAccId,
				RevenueSoGLAccId,
				RevenueExchGLAccId,
				COGS_ExchSalesOrderGLAccId,
				GoodsReceivedNotInvoicesGLAccName,
				WorkInProgressGLAccName,
				InventoryToBillGLAccName,
				FinishedGoodsGLAccName,
				InventoryExchAgreementGLAccName,
				InventoryReserveGLAccName,
				COGS_WorkOrderGLAccName,
				COGS_SalesOrderGLAccName,
				COGS_QtyVarianceGLAccName,
				COGS_UnitCostVarianceGLAccName,
				RevenueMroGLAccName,
				RevenueSoGLAccName,
				RevenueExchGLAccName,
				COGS_ExchSalesOrderGLAccName
			)
			SELECT
				im.ItemTypeId,
				im.ItemGroupId,
				im.ItemClassificationId,
				im.IsHazardousMaterial,
				im.IsExpirationDateAvailable,
				im.IsReceivedDateAvailable,
				im.DaysReceived,
				im.IsManufacturingDateAvailable,
				im.ManufacturingDays,
				im.IsTagDateAvailable,
				im.TagDays,
				im.IsOpenDateAvailable,
				im.OpenDays,
				im.IsShippedDateAvailable,
				im.ShippedDays,
				im.IsOtherDateAvailable,
				im.OtherDays,
				im.IsDER,
				im.IsSchematic,
				im.OverhaulHours,
				im.RPHours,
				im.TestHours,
				im.RFQTracking,
				im.ManufacturerId,
				im.GLAccountId,
				im.PurchaseUnitOfMeasureId,
				im.StockUnitOfMeasureId,
				im.ConsumeUnitOfMeasureId,
				im.LeadTimeDays,
				im.ReorderPoint,
				im.ReorderQuantiy,
				im.MinimumOrderQuantity,
				im.PurchaseCurrencyId,
				im.SalesCurrencyId,
				@MasterCompanyId,
				@CreatedBy,
				@CreatedBy,
				@Now,
				@Now,
				im.TurnTimeOverhaulHours,
				im.TurnTimeRepairHours,
				im.isTimeLife,
				im.isSerialized,
				im.ShelfLife,
				im.StockLevel,
				im.ShelfLifeAvailable,
				im.mfgHours,
				im.IsPma,
				im.turnTimeMfg,
				im.turnTimeBenchTest,
				im.SiteId,
				im.ItemMasterAssetTypeId,
				im.IsHotItem,
				im.IsAcquiredMethodBuy,
				im.IsOEM,
				im.MTBUR,
				im.NE,
				im.NS,
				im.OH,
				im.REP,
				im.SVC,
				LTRIM(RTRIM(p.PartNumber)),
				ISNULL(p.Description, 'N/A'),
				1,
				0,
				im.InventoryGLSettingId,
				im.GoodsReceivedNotInvoicesGLAccId,
				im.WorkInProgressGLAccId,
				im.InventoryToBillGLAccId,
				im.FinishedGoodsGLAccId,
				im.InventoryExchAgreementGLAccId,
				im.InventoryReserveGLAccId,
				im.COGS_WorkOrderGLAccId,
				im.COGS_SalesOrderGLAccId,
				im.COGS_QtyVarianceGLAccId,
				im.COGS_UnitCostVarianceGLAccId,
				im.RevenueMroGLAccId,
				im.RevenueSoGLAccId,
				im.RevenueExchGLAccId,
				im.COGS_ExchSalesOrderGLAccId,
				im.GoodsReceivedNotInvoicesGLAccName,
				im.WorkInProgressGLAccName,
				im.InventoryToBillGLAccName,
				im.FinishedGoodsGLAccName,
				im.InventoryExchAgreementGLAccName,
				im.InventoryReserveGLAccName,
				im.COGS_WorkOrderGLAccName,
				im.COGS_SalesOrderGLAccName,
				im.COGS_QtyVarianceGLAccName,
				im.COGS_UnitCostVarianceGLAccName,
				im.RevenueMroGLAccName,
				im.RevenueSoGLAccName,
				im.RevenueExchGLAccName,
				im.COGS_ExchSalesOrderGLAccName
			FROM @tbl_EmailParts p
			CROSS JOIN dbo.ItemMaster im
			WHERE im.ItemMasterId = @TemplateItemMasterId
			AND NOT EXISTS
			(
				SELECT 1
				FROM dbo.ItemMaster x WITH (NOLOCK)
				WHERE x.MasterCompanyId = @MasterCompanyId
					AND x.PartNumber = LTRIM(RTRIM(p.PartNumber))
					AND x.IsDeleted = 0
			);

			SET @NewItemMasterId = SCOPE_IDENTITY();

			EXEC dbo.UpdateItemMasterDetail @NewItemMasterId;

			-- 7. Create parts — only insert rows where ItemMaster is matched
			INSERT INTO dbo.VendorRFQPurchaseOrderPart
				(VendorRFQPurchaseOrderId, ItemMasterId, PartNumber, PartDescription,
				 ConditionId, Condition, ManufacturerId, Manufacturer, QuantityOrdered, UnitCost, ExtendedCost,
				 PriorityId, Priority, NeedByDate, ManagementStructureId, Memo,
				 MasterCompanyId, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
				 IsActive, IsDeleted, IsNoQuote)
			SELECT
				@VendorRFQPurchaseOrderId,
				im.ItemMasterId,
				LTRIM(RTRIM(p.PartNumber)),
				p.Description,
				ISNULL(c.ConditionId, 0),
				c.Description,
				im.ManufacturerId,
				im.ManufacturerName,
				ISNULL(p.RequestedQty, ISNULL(p.Qty, 0)),
				ISNULL(p.Price, 0),
				ISNULL(p.Price, 0) * ISNULL(p.RequestedQty, ISNULL(p.Qty, 0)),
				@PriorityId,
				@PriorityName,
				@NeedByDate,
				@ManagementStructureId,
				p.Notes,
				@MasterCompanyId,
				@CreatedBy, @CreatedBy, @Now, @Now,
				1, 0, 0
			FROM @tbl_EmailParts p
			LEFT JOIN dbo.Condition c WITH (NOLOCK)
				   ON c.MasterCompanyId = @MasterCompanyId
				  AND c.IsActive = 1 AND c.IsDeleted = 0
				  AND c.Description = UPPER(LTRIM(RTRIM(p.Condition)))
			INNER JOIN dbo.ItemMaster im WITH (NOLOCK)
				   ON im.MasterCompanyId = @MasterCompanyId
				  AND im.IsActive = 1 AND im.IsDeleted = 0
				  AND im.PartNumber = LTRIM(RTRIM(p.PartNumber))
				  AND im.PartDescription = LTRIM(RTRIM(p.Description))
			WHERE LTRIM(RTRIM(ISNULL(p.PartNumber, ''))) <> '';

			-- 7a. Save part management structure details into PurchaseOrderManagementStructureDetails (ModuleId = 21 = VendorRFQPOPart)
			DECLARE @PartId   BIGINT;
			DECLARE @MSPartId BIGINT;

			DECLARE part_cursor CURSOR FOR
			SELECT VendorRFQPOPartRecordId FROM dbo.VendorRFQPurchaseOrderPart WITH (NOLOCK) WHERE VendorRFQPurchaseOrderId = @VendorRFQPurchaseOrderId;

			OPEN part_cursor;
			FETCH NEXT FROM part_cursor INTO @PartId;

			WHILE @@FETCH_STATUS = 0
			BEGIN
				EXEC dbo.[PROCAddPOMSData]
					@PartId,
					@ManagementStructureId,
					@MasterCompanyId,
					@CreatedBy,
					@CreatedBy,
					21,       -- ModuleId = 21 = VendorRFQPOPart
					1,        -- Opr = 1 (insert)
					@MSPartId OUTPUT;

				FETCH NEXT FROM part_cursor INTO @PartId;
			END

			CLOSE part_cursor;
			DEALLOCATE part_cursor;

			-- 8. Update IntegrationEmail
			UPDATE dbo.IntegrationEmail
			SET ThirdPartyRFQId = @VendorRFQPurchaseOrderId
			WHERE IntegrationEmailID = @IntegrationEmailID;

			-- 9. Refresh PO detail aggregates
			EXEC dbo.PROCUpdateVendorRFQPurchaseOrderDetail @VendorRFQPurchaseOrderId;

		COMMIT TRANSACTION
     END TRY
     BEGIN CATCH  
	   IF @@trancount > 0	  
       ROLLBACK TRANSACTION;
	   -- temp table drop
	   DECLARE @ErrorLogID INT
	   ,@DatabaseName VARCHAR(100) = db_name()
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	   ,@AdhocComments VARCHAR(150) = 'usp_CreateVendorRFQPOFromEmail'
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + ISNULL(CAST(@IntegrationEmailID AS VARCHAR(100)), '') + ''''
	   ,@ApplicationName VARCHAR(100) = 'PAS'
		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID);

		RETURN (1);           
	END CATCH
END