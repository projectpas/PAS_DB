/***************************************************************  
 ** File:   [USP_CreateOrUpdateVendorBillingAddress]             
 ** Author: Ayushi Patel 
 ** Description: Create or update vendor billing address, shipping address, and check payment with audit logging 
 ** Purpose:   
 ** Date:  29-May-2025  
            
 ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------				--------------------------------            
    1    2025-05-29		  Ayushi Patel				Created
	1    2025-06-16		  Ayushi Patel				Set IsPrimary false when we add new billing address which is set to be primary
	EXEC USP_CreateOrUpdateVendorBillingAddress 0,4791,0,CAROLINA,1,'41410 ARNULFO RUN','S','','73396','VIRGINIA',1,'AYUSHI P','AYUSHI P',FALSE,TRUE,'TYREEK AUER',NULL,'',FALSE
*************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateOrUpdateVendorBillingAddress]
    @VendorBillingAddressId BIGINT = 0,
    @VendorId BIGINT,
    @AddressId BIGINT = 0,
    @City NVARCHAR(256),
    @CountryId BIGINT,
    @Address1 NVARCHAR(256),
    @Address2 NVARCHAR(256) = NULL,
    @Address3 NVARCHAR(256) = NULL,
    @PostalCode NVARCHAR(50),
    @StateOrProvince NVARCHAR(100),
    @MasterCompanyId BIGINT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100),
    @IsShipping BIT,
    @IsPrimary BIT,
    @SiteName NVARCHAR(256),
    @ContactTagId BIGINT = NULL,
    @Attention NVARCHAR(256) = NULL,
    @IsAddressForPayment BIT = 0
   
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY
        DECLARE @Now DATETIME = GETUTCDATE();
		DECLARE @NewVendorBillingAddressId BIGINT =0

		    DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
		    DECLARE @BillingAddressId INT = 1;
		    DECLARE @ShippingAddressId INT = 2;
		    DECLARE @CheckPaymentId INT = 3;
        IF @AddressId = 0
        BEGIN
            INSERT INTO [dbo].[Address] (
                City, CountryId, Line1, Line2, Line3, MasterCompanyId, PostalCode, StateOrProvince,
                IsActive, IsDeleted, CreatedBy, UpdatedBy, CreatedDate, UpdatedDate
            ) VALUES (
                @City, @CountryId, @Address1, @Address2, @Address3, @MasterCompanyId, @PostalCode, @StateOrProvince,
                1, 0, @CreatedBy, @UpdatedBy, @Now, @Now
            );
            SET @AddressId = SCOPE_IDENTITY();
        END
        ELSE
        BEGIN
            UPDATE [dbo].[Address]
            SET City = @City, CountryId = @CountryId, Line1 = @Address1, Line2 = @Address2, Line3 = @Address3,
                MasterCompanyId = @MasterCompanyId, PostalCode = @PostalCode, StateOrProvince = @StateOrProvince,
                UpdatedBy = @UpdatedBy, UpdatedDate = @Now
            WHERE AddressId = @AddressId;
        END

        IF @IsShipping = 1
        BEGIN
            IF @IsPrimary = 1
            BEGIN
                UPDATE VS
                SET IsPrimary = 0
                FROM dbo.VendorShippingAddress VS
                WHERE VS.VendorId = @VendorId AND VS.IsPrimary = 1;

				DECLARE @VendorShippingAddressId BIGINT = (SELECT TOP 1 VendorShippingAddressId FROM dbo.VendorShippingAddress WITH(NOLOCK) WHERE VendorId = @VendorId AND ISNULL(IsPrimary,0) = 0 ORDER BY UpdatedDate DESC )
				EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @VendorShippingAddressId , @ShippingAddressId, @UpdatedBy;
            END

            INSERT INTO DBO.VendorShippingAddress (
                VendorId, AddressId, IsPrimary, SiteName, ContactTagId, Attention, MasterCompanyId,
                CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
            ) VALUES (
                @VendorId, @AddressId, ISNULL(@IsPrimary, 0), @SiteName, @ContactTagId, @Attention, @MasterCompanyId,
                @CreatedBy, @UpdatedBy, @Now, @Now, 1, 0
            );

            DECLARE @NewVendorShippingAddressId BIGINT = SCOPE_IDENTITY();
			EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @NewVendorShippingAddressId, @ShippingAddressId, @UpdatedBy;
        END

        IF @VendorBillingAddressId > 0
        BEGIN
            IF @IsPrimary = 1
            BEGIN
			PRINT (@ContactTagId);
                UPDATE VB
                SET IsPrimary = 0,
                    ContactTagId = @ContactTagId,
                    Attention = @Attention,
                    UpdatedBy = @CreatedBy,
                    UpdatedDate = @Now
                FROM DBO.VendorBillingAddress VB
                WHERE VB.VendorId = @VendorId AND VB.IsPrimary = 1 AND VB.VendorBillingAddressId <> @VendorBillingAddressId;
                EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @VendorBillingAddressId, @BillingAddressId, @CreatedBy;
            END

            UPDATE DBO.VendorBillingAddress
            SET SiteName = @SiteName, VendorId = @VendorId, IsPrimary = @IsPrimary, AddressId = @AddressId,
                ContactTagId = @ContactTagId, Attention = @Attention, MasterCompanyId = @MasterCompanyId,
                UpdatedBy = @UpdatedBy, UpdatedDate = @Now
            WHERE VendorBillingAddressId = @VendorBillingAddressId;
            EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @VendorBillingAddressId, @BillingAddressId, @UpdatedBy;
            SET @NewVendorBillingAddressId = @VendorBillingAddressId;
        END
        ELSE
        BEGIN
		
            IF NOT EXISTS (SELECT 1 FROM DBO.VendorBillingAddress WITH(NOLOCK) WHERE VendorId = @VendorId)
                SET @IsPrimary = 1;

				IF @IsPrimary = 1
				BEGIN
				PRINT (@ContactTagId);
					UPDATE VB
					SET IsPrimary = 0,
						ContactTagId = @ContactTagId,
						Attention = @Attention,
						UpdatedBy = @CreatedBy,
						UpdatedDate = @Now
					FROM DBO.VendorBillingAddress VB
					WHERE VB.VendorId = @VendorId AND VB.IsPrimary = 1 ;
                
            END 
            INSERT INTO DBO.VendorBillingAddress (
                VendorId, AddressId, IsPrimary, SiteName, ContactTagId, Attention, MasterCompanyId,
                CreatedBy, UpdatedBy, CreatedDate, UpdatedDate, IsActive, IsDeleted
            ) VALUES (
                @VendorId, @AddressId, ISNULL(@IsPrimary, 0), @SiteName, @ContactTagId, @Attention, @MasterCompanyId,
                @CreatedBy, @UpdatedBy, @Now, @Now, 1, 0
            );

            SET @NewVendorBillingAddressId = SCOPE_IDENTITY();
            EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @NewVendorBillingAddressId, @BillingAddressId, @UpdatedBy;

            IF @IsAddressForPayment = 1
            BEGIN
                IF @IsPrimary = 1
                BEGIN
                    DECLARE @ExistingCheckPaymentId BIGINT;

                    SELECT TOP 1 @ExistingCheckPaymentId = cp.CheckPaymentId
                    FROM DBO.CheckPayment cp WITH(NOLOCK)
                    JOIN DBO.VendorCheckPayment vcp WITH(NOLOCK) ON cp.CheckPaymentId = vcp.CheckPaymentId
                    WHERE vcp.VendorId = @VendorId AND cp.IsPrimayPayment = 1;

                    IF @ExistingCheckPaymentId IS NOT NULL
                    BEGIN
                        UPDATE DBO.CheckPayment
                        SET IsPrimayPayment = 0
                        WHERE CheckPaymentId = @ExistingCheckPaymentId;
                        EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @ExistingCheckPaymentId, @CheckPaymentId, @UpdatedBy;
                    END
                END

                INSERT INTO DBO.CheckPayment (
                    SiteName, MasterCompanyId, IsActive, IsPrimayPayment, CreatedDate,
                    UpdatedDate, IsDeleted, CreatedBy, UpdatedBy, AddressId
                ) VALUES (
                    @SiteName, @MasterCompanyId, 1, ISNULL(@IsPrimary, 0), @Now,
                    @Now, 0, @CreatedBy, @UpdatedBy, @AddressId
                );

                DECLARE @NewCheckPaymentId BIGINT = SCOPE_IDENTITY();
                EXEC USP_ShippingBillingAddressHistory @VendorId, @VendorModuleId, @NewCheckPaymentId, @CheckPaymentId, @UpdatedBy;

                INSERT INTO VendorCheckPayment (
                    VendorId, MasterCompanyId, CheckPaymentId, CreatedDate, UpdatedDate,
                    CreatedBy, UpdatedBy, IsActive
                ) VALUES (
                    @VendorId, @MasterCompanyId, @NewCheckPaymentId, @Now, @Now,
                    @CreatedBy, @UpdatedBy, 1
                );
            END
        END

        SELECT @NewVendorBillingAddressId NewVendorBillingAddressId
    END TRY
    BEGIN CATCH
		SELECT
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_STATE() AS ErrorState,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;
        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
                @AdhocComments VARCHAR(150) = 'USP_CreateOrUpdateVendorBillingAddress',
                @ProcedureParameters VARCHAR(3000) = '@VendorId = ' + CAST(ISNULL(@VendorId, 0) AS VARCHAR),
                @ApplicationName VARCHAR(100) = 'PAS';
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException 
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected error occurred in the database. Please let the support team know of the error number: %d',
            16, 1, @ErrorLogID
        );
        RETURN (1);
    END CATCH
END