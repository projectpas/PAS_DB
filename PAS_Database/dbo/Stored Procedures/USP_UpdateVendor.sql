/*************************************************************           
** File:  [USP_UpdateVendor]
** Author:   Ayushi Patel  
** Description: Updates Vendor and associated Customer (if IsVendorAlsoCustomer is true)
** Purpose:  
** Date:   09-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author               Change Description            
** --    --------      -------              -------------------------------          
** 1     09-07-2025    Ayushi Patel         Created  
** 2     08-Dec-2025   Bhargav Saliya       Add SP [USP_UpdateVendorContact] for Updat Vendor Contact Detail
** 3     09-JUNE-2026  Priyansh Patel       Added Flow to create Customer if not available [PN-16747]
** 4     24-June-2026  Sahdev Saliya        Added Notes [PN-16968]
** 5     02-July-2026  Sahdev Saliya        Added Resale Number [PN-17018]
** 6     06-July-2026  Divyesh Kathitiya    Added VAT Number [PN-17124]  
** 7     01-Aug-2026   Bhargav Saliya       When we update a vendor at a time, there is no need to update the customer type [PN-17519]
** 8     12-AUG-2026   Moin Bloch           Added LegalEntityId PN-17651
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendor]
    @VendorId BIGINT,
    @VendorName NVARCHAR(200),
    @LicenseNumber NVARCHAR(100),
    @VendorPhone NVARCHAR(50),
    @VendorPhoneExt NVARCHAR(20),
    @VendorTypeId BIGINT,
    @IsPreferredVendor BIT,
    @IsParent BIT,
    @IsVendorAlsoCustomer BIT,
    @VendorEmail NVARCHAR(200),
    @VendorContractReference NVARCHAR(200),
    @DoingBusinessAsName NVARCHAR(200),
    @VendorURL NVARCHAR(200),
    @IsCertified BIT,
    @VendorAudit BIT,
    @MasterCompanyId BIGINT,
    @CreditTermsId BIGINT = NULL,
    @UpdatedBy NVARCHAR(100),
    @IsDeleted BIT,
    @IsAddressForBilling BIT,
    @IsAddressForShipping BIT,
    @VendorParentId BIGINT = NULL,
    @LegalEntityId BIGINT = NULL,
    @IsTradeRestricted BIT = 0,
    @TradeRestrictedMemo NVARCHAR(MAX) = NULL,
    @IsTrackScoreCard BIT = 0,
    @IsVendorOnHold BIT = 0,
    @IsWarningRestriction BIT = 0,
    @Address1 NVARCHAR(200),
    @Address2 NVARCHAR(200) = NULL,
    @Address3 NVARCHAR(200) = NULL,
    @PostalCode NVARCHAR(20),
    @StateOrProvince NVARCHAR(100),
    @City NVARCHAR(100),
    @CountryId BIGINT,
    @IsActive BIT,
    @VendorClassificationIds TVP_BigInt READONLY,
    @IntegrationPortalIds TVP_BigInt READONLY,
	@Notes NVARCHAR(MAX) = NULL,
	@ResaleNumber VARCHAR(200) = NULL,
    @VatNumber VARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @AddressId BIGINT, @VendorModuleId INT, @RelatedCustomerId BIGINT;
        DECLARE @ShippingAddressType INT = 2, @BillingAddressType INT = 1;
        DECLARE @VendorAccountingModuleId INT = (
            SELECT TOP 1 AccountingModuleId 
            FROM DBO.AccountingModule WITH(NOLOCK) 
            WHERE AccountingModuleName = 'Vendor'
        );

        SET @VendorModuleId = (
            SELECT TOP 1 AttachmentModuleId 
            FROM DBO.AttachmentModule WITH(NOLOCK) 
            WHERE Name = 'Vendor'
        );

        -- Update Address
        EXEC USP_AddAddress
            @Address1, @Address2, @Address3, @PostalCode, @StateOrProvince, @City,
            @CountryId, @MasterCompanyId, @UpdatedBy, @UpdatedBy, @AddressId OUTPUT;

        -- Update Vendor
        UPDATE Vendor
        SET VendorName = @VendorName,
            LicenseNumber = @LicenseNumber,
            VendorPhone = @VendorPhone,
            VendorPhoneExt = @VendorPhoneExt,
            VendorTypeId = @VendorTypeId,
            IsPreferredVendor = @IsPreferredVendor,
            IsParent = @IsParent,
            IsVendorAlsoCustomer = @IsVendorAlsoCustomer,
            VendorEmail = @VendorEmail,
            VendorContractReference = @VendorContractReference,
            DoingBusinessAsName = @DoingBusinessAsName,
            VendorURL = @VendorURL,
            IsCertified = @IsCertified,
            VendorAudit = @VendorAudit,
            IsDeleted = @IsDeleted,
            CreditTermsId = @CreditTermsId,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy,
            IsAddressForBilling = @IsAddressForBilling,
            IsAddressForShipping = @IsAddressForShipping,
            VendorParentId = @VendorParentId,
            LegalEntityId = @LegalEntityId,
            AddressId = @AddressId,
            IsTradeRestricted = @IsTradeRestricted,
            TradeRestrictedMemo = @TradeRestrictedMemo,
            IsTrackScoreCard = @IsTrackScoreCard,
            IsVendorOnHold = @IsVendorOnHold,
            IsWarningRestriction = @IsWarningRestriction,
            IsActive = @IsActive,
			Notes = @Notes,
			ResaleNumber = @ResaleNumber,
            VatNumber = @VatNumber
        WHERE VendorId = @VendorId;

        -- Update Vendor Shipping/Billing Address
        IF @IsAddressForShipping = 1
        BEGIN
            DECLARE @VendorShippingAddressId BIGINT;

            SELECT TOP 1 @VendorShippingAddressId = VendorShippingAddressId
            FROM VendorShippingAddress WITH (NOLOCK)
            WHERE VendorId = @VendorId;

            UPDATE VendorShippingAddress
            SET AddressId = @AddressId,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE VendorId = @VendorId;

            UPDATE Vendor SET ShippingAddressId = @AddressId WHERE VendorId = @VendorId;

            EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @VendorShippingAddressId, @ShippingAddressType, @UpdatedBy;
        END

        IF @IsAddressForBilling = 1
        BEGIN
            DECLARE @VendorBillingAddressId BIGINT;

            SELECT TOP 1 @VendorBillingAddressId = VendorBillingAddressId
            FROM VendorBillingAddress WITH (NOLOCK)
            WHERE VendorId = @VendorId;

            EXEC USP_ShippingBillingAddressHistory 
                @VendorId, 
                @VendorModuleId, 
                @VendorBillingAddressId, 
                @BillingAddressType, 
                @UpdatedBy;

            UPDATE VendorBillingAddress
            SET AddressId = @AddressId,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE VendorId = @VendorId;

            UPDATE Vendor SET BillingAddressId = @AddressId WHERE VendorId = @VendorId;

            EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @VendorBillingAddressId, @BillingAddressType, @UpdatedBy;
        END

        -- Delete + Recreate Vendor Classification Mappings
        DELETE FROM ClassificationMapping
        WHERE ReferenceId = @VendorId AND ModuleId = @VendorModuleId;

        EXEC USP_CreateClassificationMappings 
            @VendorClassificationIds, 
            @VendorModuleId, 
            @VendorId, 
            @UpdatedBy;

        -- Delete + Recreate Integration Portal Mappings
        DELETE FROM IntegrationPortalMapping
        WHERE ReferenceId = @VendorId AND ModuleId = @VendorModuleId;

        EXEC USP_CreateIntegrationMappings 
            @IntegrationPortalIds, 
            @VendorModuleId, 
            @VendorId, 
            @UpdatedBy;

		-- Updat Vendor Contact Detail
		EXEC [dbo].[USP_UpdateVendorContact] @VendorId,@VendorEmail, @VendorPhone, @VendorPhoneExt, @UpdatedBy
        -- If Vendor is also Customer, update Customer
        IF @IsVendorAlsoCustomer = 1
        BEGIN
		 SELECT TOP 1 @RelatedCustomerId = CustomerId 
		 FROM Customer WITH(NOLOCK) 
		 WHERE LOWER(Name) = LOWER(@VendorName);

            SELECT TOP 1 @RelatedCustomerId = RelatedCustomerId  FROM Vendor WITH(NOLOCK) WHERE VendorId = @VendorId;


            IF @RelatedCustomerId IS NOT NULL
            BEGIN
                UPDATE Customer
                SET CustomerAffiliationId = @VendorTypeId,
                    Name = @VendorName,
                    IsParent = 0,
                    Email = @VendorEmail,
                    CustomerPhone = @VendorPhone,
                    CustomerPhoneExt = @VendorPhoneExt,
                    IsAddressForBilling = @IsAddressForBilling,
                    IsAddressForShipping = @IsAddressForShipping,
                    IsCustomerAlsoVendor = @IsVendorAlsoCustomer,
                    CustomerCode = CustomerCode,
                    CustomerURL = @VendorURL,
                    MasterCompanyId = @MasterCompanyId,
                    UpdatedDate = GETUTCDATE(),
                    UpdatedBy = @UpdatedBy,
                    IsActive = 1,
                    IsDeleted = 0,
                    AddressId = @AddressId,
					Memo = @Notes,
					ResaleNumber = @ResaleNumber,
                    VatNumber = @VatNumber
                WHERE CustomerId = @RelatedCustomerId;

                IF @IsAddressForShipping = 1
                BEGIN
                    UPDATE CustomerDomensticShipping
                    SET AddressId = @AddressId,
                        UpdatedBy = @UpdatedBy,
                        UpdatedDate = GETUTCDATE()
                    WHERE CustomerId = @RelatedCustomerId;

                    UPDATE Customer 
                    SET ShippingAddressId = @AddressId 
                    WHERE CustomerId = @RelatedCustomerId;
                END

                IF @IsAddressForBilling = 1
                BEGIN
                    UPDATE CustomerBillingAddress
                    SET AddressId = @AddressId,
                        UpdatedBy = @UpdatedBy,
                        UpdatedDate = GETUTCDATE()
                    WHERE CustomerId = @RelatedCustomerId;

                    UPDATE Customer 
                    SET BillingAddressId = @AddressId 
                    WHERE CustomerId = @RelatedCustomerId;
                END

                EXEC USP_AddCustomerDefaultContact
                    @RelatedCustomerId, @VendorName, @VendorEmail, @VendorPhone, @VendorPhoneExt,
                    @MasterCompanyId, 1, @UpdatedBy, @UpdatedBy;

                UPDATE Vendor 
                SET RelatedCustomerId = @RelatedCustomerId 
                WHERE VendorId = @VendorId;
            END
            ELSE
            BEGIN

					DECLARE @CustomerCode NVARCHAR(50);
					DECLARE @CustPrefixId BIGINT = 0;
					DECLARE @CustPrefix VARCHAR(50) = '';
					DECLARE @CustSuffix VARCHAR(50) = '';
					DECLARE @CustCurrentNo BIGINT = 0;
                    DECLARE @CustomerTypeId INT;
		            
                    SELECT @CustomerTypeId = CustomerTypeId FROM [dbo].[CustomerType] WITH(NOLOCK) WHERE CustomerTypeName = 'CUSTOMER' AND MasterCompanyId = @MasterCompanyId

						SELECT 
							@CustCurrentNo = ISNULL(CP.CurrentNummber, CP.StartsFrom), 
							@CustPrefixId = CP.CodePrefixId,
							@CustPrefix = CP.CodePrefix,
							@CustSuffix = CP.CodeSufix
						FROM dbo.CodeTypes CT WITH (NOLOCK)
						INNER JOIN dbo.CodePrefixes CP WITH (NOLOCK) ON CT.CodeTypeId = CP.CodeTypeId
						WHERE 
							CT.IsActive = 1 AND CT.IsDeleted = 0 AND
							CP.IsActive = 1 AND CP.IsDeleted = 0 AND
							CP.MasterCompanyId = @MasterCompanyId AND
							CT.CodeType = 'Customer';

						-- Increment number
						SET @CustCurrentNo = @CustCurrentNo + 1;

						-- Generate the code using function
						SET @CustomerCode = (SELECT * FROM dbo.udfGenerateCodeNumberWithoutDash(@CustCurrentNo, @CustPrefix, @CustSuffix));
                
				INSERT INTO Customer (
										CustomerAffiliationId,
										CustomerTypeId,
										Name,
										CustomerCode,
										DoingBuinessAsName,
										IsParent,
										ParentId,
										CustomerPhone,
										CustomerPhoneExt,
										Email,
										AddressId,
										IsAddressForBilling,
										IsAddressForShipping,
										IsCustomerAlsoVendor,
										ContractReference,
										IsPBHCustomer,
										PBHCustomerMemo,
										CustomerURL,
										RestrictPMA,
										RestrictDER,
										ManagementStructureId,
										MasterCompanyId,
										CreatedBy,
										UpdatedBy,
										CreatedDate,
										UpdatedDate,
										IsActive,
										IsDeleted,
										IsCRMCustomer,
										BillingAddressId,
										ShippingAddressId,
										IsTradeRestricted,
										TradeRestrictedMemo,
										IsTrackScoreCard,
										CommunicationPreference,
										Ismiscellaneous,
										IsStageChange,
										IsCommunicationPreference,
										IsCustomerShipping,
										QuickBooksReferenceId,
										IsUpdated,
										LastSyncDate,
										Memo,
										SyncToken,
										ResaleNumber,
                                        VatNumber
									)
									VALUES (
										@VendorTypeId,
										@CustomerTypeId,
										@VendorName,
										@CustomerCode,
										@DoingBusinessAsName,
										0,
										NULL, -- Assuming ParentId is not available
										@VendorPhone,
										@VendorPhoneExt,
										@VendorEmail,
										@AddressId,
										@IsAddressForBilling,
										@IsAddressForShipping,
										@IsVendorAlsoCustomer,
										@VendorContractReference,
										0, -- IsPBHCustomer default false
										NULL, -- PBHCustomerMemo not available
										@VendorURL,
										0, -- RestrictPMA default false
										0, -- RestrictDER default false
										NULL, -- ManagementStructureId not available
										@MasterCompanyId,
										@UpdatedBy,
										@UpdatedBy,
										GETUTCDATE(),
										GETUTCDATE(),
										1,
										0, -- IsDeleted default false
										0, -- IsCRMCustomer default false
										NULL, -- BillingAddressId will be set later
										NULL, -- ShippingAddressId will be set later
										@IsTradeRestricted,
										@TradeRestrictedMemo,
										@IsTrackScoreCard,
										NULL, -- CommunicationPreference not provided
										0, -- Ismiscellaneous default false
										NULL, -- IsStageChange not provided
										NULL, -- IsCommunicationPreference not provided
										NULL, -- IsCustomerShipping not provided
										NULL, -- QuickBooksReferenceId not available
										NULL, -- IsUpdated default true
										NULL, -- LastSyncDate
										@Notes, -- Memo
										NULL,  -- SyncToken
										@ResaleNumber, -- ResaleNumber
                                        @VatNumber -- VAT Number
									);

                SET @RelatedCustomerId = SCOPE_IDENTITY();

                UPDATE CodePrefixes SET CurrentNummber = @CustCurrentNo WHERE CodePrefixId = @CustPrefixId;
                DECLARE @CustomerClassificationId BIGINT;
                SELECT TOP 1 @CustomerClassificationId = CustomerClassificationId FROM CustomerClassification WITH(NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0;

                IF @CustomerClassificationId IS NOT NULL
                BEGIN
                    INSERT INTO ClassificationMapping (ClasificationId, ModuleId, ReferenceId, IsActive, IsDeleted, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate)
                    VALUES (@CustomerClassificationId, 9, @RelatedCustomerId, 1, 0, @UpdatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE());
                END
                IF @IsAddressForShipping = 1
                BEGIN
                    INSERT INTO CustomerDomensticShipping (CustomerId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsPrimary, IsDeleted)
                    VALUES (@RelatedCustomerId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @UpdatedBy, @UpdatedBy, 1, 1, 0);
                    UPDATE Customer SET ShippingAddressId = @AddressId WHERE CustomerId = @RelatedCustomerId;
                END
                IF @IsAddressForBilling = 1
                BEGIN
                    INSERT INTO CustomerBillingAddress (CustomerId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsPrimary, IsActive, IsDeleted)
                    VALUES (@RelatedCustomerId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @UpdatedBy, @UpdatedBy, 1, 1, 0);
                    UPDATE Customer SET BillingAddressId = @AddressId WHERE CustomerId = @RelatedCustomerId;
                END
				PRINT @RelatedCustomerId;
                EXEC USP_AddCustomerDefaultContact @RelatedCustomerId, @VendorName, @VendorEmail, @VendorPhone, @VendorPhoneExt, @MasterCompanyId, 1, @UpdatedBy, @UpdatedBy;
                UPDATE Vendor SET RelatedCustomerId = @RelatedCustomerId WHERE VendorId = @VendorId;
            END

        END

        -- Finalize
          EXEC QuickBooks_UpdateModuleCountDetails @MasterCompanyId, @VendorAccountingModuleId;

        COMMIT;
    END TRY
    BEGIN CATCH
        SELECT  
            ERROR_NUMBER() AS ErrorNumber,
            ERROR_SEVERITY() AS ErrorSeverity,
            ERROR_STATE() AS ErrorState,
            ERROR_PROCEDURE() AS ErrorProcedure,
            ERROR_LINE() AS ErrorLine,
            ERROR_MESSAGE() AS ErrorMessage;

        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = 'USP_UpdateVendor',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected Error Occured in the database. Please let the support team know of the error number : %d',
            16, 1, @ErrorLogID
        );

        RETURN (1);
    END CATCH
END