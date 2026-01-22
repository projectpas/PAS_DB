/*************************************************************           
** File:  [USP_UpdateVendor]
** Author:   Ayushi Patel  
** Description: Updates Vendor and associated Customer (if IsVendorAlsoCustomer is true)
** Purpose:  
** Date:   09-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     09-07-2025   Ayushi Patel      Created  
   2     08-Dec-2025  Bhargav Saliya    Add SP [USP_UpdateVendorContact] for Updat Vendor Contact Detail
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
    @IntegrationPortalIds TVP_BigInt READONLY
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
            AddressId = @AddressId,
            IsTradeRestricted = @IsTradeRestricted,
            TradeRestrictedMemo = @TradeRestrictedMemo,
            IsTrackScoreCard = @IsTrackScoreCard,
            IsVendorOnHold = @IsVendorOnHold,
            IsWarningRestriction = @IsWarningRestriction,
            IsActive = @IsActive
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
                    CustomerTypeId = @VendorTypeId,
                    IsCustomerAlsoVendor = @IsVendorAlsoCustomer,
                    CustomerCode = CustomerCode,
                    CustomerURL = @VendorURL,
                    MasterCompanyId = @MasterCompanyId,
                    UpdatedDate = GETUTCDATE(),
                    UpdatedBy = @UpdatedBy,
                    IsActive = 1,
                    IsDeleted = 0,
                    AddressId = @AddressId
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