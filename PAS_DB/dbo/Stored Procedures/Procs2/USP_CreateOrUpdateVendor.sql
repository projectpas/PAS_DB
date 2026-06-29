/*************************************************************           
** File:  [USP_CreateOrUpdateVendor]
** Author:   Ayushi Patel  
** Description: Create or Update Vendor with Address, Contact, Payment, Integration, and Customer Mapping
** Purpose:  
** Date:   07-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     07-07-2025   Ayushi Patel      Created  
** 2     08-APR-2026   Hemant Saliya     Corrected to Get customer type Id based on name  
** 3     22-APR-2026   Moin Bloch        Moved to API Due TO Xero Accounting Changes PN-16009
** 4     09-JUNE-2026  Priyansh Patel    Fixed the issue with the @ExistingCustomerId [PN-16747]
** 5     25-June-2026  Sahdev Saliya     Added Notes [PN-16968]
** 6     26-June-2026  Sahdev Saliya     Fixed the issue with the @Notes [PN-16968]

**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateOrUpdateVendor]
    @VendorId BIGINT OUTPUT,
    @VendorName NVARCHAR(200),
    @LicenseNumber NVARCHAR(100),
    @VendorPhone NVARCHAR(50),
    @VendorPhoneExt NVARCHAR(20),
    @VendorTypeId BIGINT,
    @IsPreferredVendor BIT,
    @IsParent BIT,
    @IsVendorAlsoCustomer BIT,
    @VendorEmail NVARCHAR(200),
    @VendorCode NVARCHAR(50) = NULL,
    @VendorContractReference NVARCHAR(200),
    @DoingBusinessAsName NVARCHAR(200),
    @VendorURL NVARCHAR(200),
    @IsCertified BIT,
    @VendorAudit BIT,
    @MasterCompanyId BIGINT,
    @CreditTermsId BIGINT = NULL,
    @CreatedBy NVARCHAR(100),
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
    @IntegrationPortalIds TVP_BigInt READONLY,
    @CustomerCreditPaymentDetailId BIGINT = NULL,
	@IsAllowNettingAPAR BIT,
	@EDI BIT,
	@EDIDescription NVARCHAR(100) = NULL,
	@AeroExchange BIT,
	@AeroExchangeDescription NVARCHAR(100) = NULL,
	@CreditLimit DECIMAL(18,2) = NULL,
	@CurrencyId INT = NULL,
	@DiscountId BIGINT = NULL,
	@Is1099Required BIT,
	@Notes NVARCHAR(MAX) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRAN;

        DECLARE @AddressId BIGINT, @VendorShippingAddressId BIGINT, @VendorBillingAddressId BIGINT, @RelatedCustomerId BIGINT;
		DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
		DECLARE @VendorAccountingModuleId INT = (select TOP 1 AccountingModuleId from DBO.AccountingModule WITH(NOLOCK) WHERE AccountingModuleName='Vendor')
		DECLARE @BillingAddressId INT = 1;
		DECLARE @ShippingAddressId INT = 2;
		DECLARE @CustomerTypeId INT;
		SELECT @CustomerTypeId = CustomerTypeId FROM [dbo].[CustomerType] WITH(NOLOCK) WHERE CustomerTypeName = 'CUSTOMER' AND MasterCompanyId = @MasterCompanyId

        EXEC USP_AddAddress
            @Address1, @Address2, @Address3, @PostalCode, @StateOrProvince, @City,
            @CountryId, @MasterCompanyId, @CreatedBy, @UpdatedBy, @AddressId OUTPUT;

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

        INSERT INTO Vendor (
			VendorName, LicenseNumber, VendorPhone, VendorPhoneExt, VendorTypeId, IsPreferredVendor,
			IsParent, IsVendorAlsoCustomer, VendorEmail, VendorCode, VendorContractReference,
			DoingBusinessAsName, VendorURL, IsCertified, VendorAudit, MasterCompanyId, IsActive,
			IsDeleted, CreditTermsId, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy,
			IsAddressForBilling, IsAddressForShipping, VendorParentId, AddressId,
			IsAllowNettingAPAR, IsTradeRestricted, TradeRestrictedMemo, IsTrackScoreCard,
			IsVendorOnHold, IsUpdated, IsWarningRestriction,
			Is1099Required, EDI, EDIDescription, AeroExchange, AeroExchangeDescription,
			CreditLimit, CurrencyId, DiscountId, IsAllow, IsWarning, IsRestrict, Notes
		)
		VALUES (
			@VendorName, @LicenseNumber, @VendorPhone, @VendorPhoneExt, @VendorTypeId, @IsPreferredVendor,
			@IsParent, @IsVendorAlsoCustomer, @VendorEmail, @VendorCode, @VendorContractReference,
			@DoingBusinessAsName, @VendorURL, @IsCertified, @VendorAudit, @MasterCompanyId, @IsActive,
			@IsDeleted, @CreditTermsId, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy,
			@IsAddressForBilling, @IsAddressForShipping, @VendorParentId, @AddressId,
			@IsAllowNettingAPAR, @IsTradeRestricted, @TradeRestrictedMemo, @IsTrackScoreCard,
			@IsVendorOnHold, 1, @IsWarningRestriction,
			@Is1099Required, @EDI, @EDIDescription, @AeroExchange, @AeroExchangeDescription,
			@CreditLimit, @CurrencyId, @DiscountId, 1, 0, 0, @Notes
		);

        SET @VendorId = SCOPE_IDENTITY();

        EXEC USP_AddOrUpdateVendorDefaultContact @VendorId, @VendorName, @VendorEmail, @VendorPhone, @VendorPhoneExt, @MasterCompanyId, @CreatedBy, @UpdatedBy;
        EXEC USP_AddVendorPayment @VendorId, @VendorName, @Address1, @Address2, @PostalCode, @StateOrProvince, @City, @CountryId, @MasterCompanyId, @CreatedBy, @UpdatedBy;
        EXEC USP_CreateClassificationMappings @VendorClassificationIds, 3, @VendorId, @CreatedBy;
        EXEC USP_CreateIntegrationMappings @IntegrationPortalIds, 3, @VendorId, @CreatedBy;

        IF @IsAddressForShipping = 1
        BEGIN
            INSERT INTO VendorShippingAddress (
                VendorId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsPrimary, IsDeleted
            )
            VALUES (
                @VendorId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy, 1, 1, 0
            );

            SET @VendorShippingAddressId = SCOPE_IDENTITY();

            UPDATE Vendor SET ShippingAddressId = @AddressId WHERE VendorId = @VendorId;

            EXEC USP_ShippingBillingAddressHistory 
                @VendorId, @VendorModuleId, @VendorShippingAddressId, @ShippingAddressId, @UpdatedBy;
        END

        IF @IsAddressForBilling = 1
        BEGIN
            INSERT INTO VendorBillingAddress (
                VendorId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsPrimary, IsDeleted
            )
            VALUES (
                @VendorId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy, 1, 1, 0
            );

            SET @VendorBillingAddressId = SCOPE_IDENTITY();

            UPDATE Vendor SET BillingAddressId = @AddressId WHERE VendorId = @VendorId;

            EXEC USP_ShippingBillingAddressHistory 
                @VendorId, @VendorModuleId, @VendorBillingAddressId, @BillingAddressId, @UpdatedBy;
        END

        IF @IsVendorAlsoCustomer = 1
        BEGIN
            DECLARE @ExistingCustomerId BIGINT;
            SELECT TOP 1 @ExistingCustomerId = RelatedCustomerId  FROM Vendor WITH(NOLOCK) WHERE VendorId = @VendorId;

            IF @ExistingCustomerId IS NULL
            BEGIN
					DECLARE @CustomerCode NVARCHAR(50);
					DECLARE @CustPrefixId BIGINT = 0;
					DECLARE @CustPrefix VARCHAR(50) = '';
					DECLARE @CustSuffix VARCHAR(50) = '';
					DECLARE @CustCurrentNo BIGINT = 0;

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
										SyncToken
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
										@CreatedBy,
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
										NULL  -- SyncToken
									);

                SET @RelatedCustomerId = SCOPE_IDENTITY();

                UPDATE CodePrefixes SET CurrentNummber = @CustCurrentNo WHERE CodePrefixId = @CustPrefixId;
                DECLARE @CustomerClassificationId BIGINT;
                SELECT TOP 1 @CustomerClassificationId = CustomerClassificationId FROM CustomerClassification WITH(NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0;

                IF @CustomerClassificationId IS NOT NULL
                BEGIN
                    INSERT INTO ClassificationMapping (ClasificationId, ModuleId, ReferenceId, IsActive, IsDeleted, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate)
                    VALUES (@CustomerClassificationId, 9, @RelatedCustomerId, 1, 0, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE());
                END
                IF @IsAddressForShipping = 1
                BEGIN
                    INSERT INTO CustomerDomensticShipping (CustomerId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsActive, IsPrimary, IsDeleted)
                    VALUES (@RelatedCustomerId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy, 1, 1, 0);
                    UPDATE Customer SET ShippingAddressId = @AddressId WHERE CustomerId = @RelatedCustomerId;
                END
                IF @IsAddressForBilling = 1
                BEGIN
                    INSERT INTO CustomerBillingAddress (CustomerId, AddressId, MasterCompanyId, SiteName, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy, IsPrimary, IsActive, IsDeleted)
                    VALUES (@RelatedCustomerId, @AddressId, @MasterCompanyId, @VendorName, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy, 1, 1, 0);
                    UPDATE Customer SET BillingAddressId = @AddressId WHERE CustomerId = @RelatedCustomerId;
                END
				PRINT @RelatedCustomerId;
                EXEC USP_AddCustomerDefaultContact @RelatedCustomerId, @VendorName, @VendorEmail, @VendorPhone, @VendorPhoneExt, @MasterCompanyId, 1, @CreatedBy, @UpdatedBy;
                UPDATE Vendor SET RelatedCustomerId = @RelatedCustomerId WHERE VendorId = @VendorId;
            END
        END

        IF @CustomerCreditPaymentDetailId > 0
        BEGIN
            UPDATE CustomerCreditPaymentDetail
            SET VendorId = @VendorId, UpdatedDate = GETUTCDATE(), UpdatedBy = @UpdatedBy
            WHERE CustomerCreditPaymentDetailId = @CustomerCreditPaymentDetailId;
        END
        --EXEC QuickBooks_UpdateModuleCountDetails @MasterCompanyId, @VendorAccountingModuleId;
        COMMIT;
    END TRY
      BEGIN CATCH
          SELECT  
            ERROR_NUMBER() AS ErrorNumber  
            ,ERROR_SEVERITY() AS ErrorSeverity  
            ,ERROR_STATE() AS ErrorState  
            ,ERROR_PROCEDURE() AS ErrorProcedure  
            ,ERROR_LINE() AS ErrorLine  
            ,ERROR_MESSAGE() AS ErrorMessage;  

		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
		DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = '[USP_CreateOrUpdateVendor]',
            @ProcedureParameters varchar(3000) = '',
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
    RETURN (1);
  END CATCH
END