/*************************************************************
** File:[USP_AddVendorPayment]
** Author:   Ayushi Patel
** Description: Add Vendor Payment
** Purpose:  
** Date:     07-07-2025
**************************************************************
** Change History
**************************************************************
** PR   Date         Author         Change Description
** --   ----------   ------------   --------------------------------
** 1    07-07-2025   Ayushi Patel   Created

-- EXEC USP_AddAddress 4797
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddVendorPayment]
(
    @VendorId BIGINT,
    @VendorName NVARCHAR(200),
    @Address1 NVARCHAR(100),
    @Address2 NVARCHAR(100) = NULL,
    @PostalCode NVARCHAR(50) = NULL,
    @StateOrProvince NVARCHAR(100) = NULL,
    @City NVARCHAR(100) = NULL,
    @CountryId BIGINT = NULL,
    @MasterCompanyId BIGINT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100)
)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @AddressId BIGINT,
                @NewCheckPaymentId BIGINT;
		DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
		DECLARE @CheckPaymentId INT = 3;

        INSERT INTO [dbo].[Address]
        (
            Line1, Line2, PostalCode, StateOrProvince, City,
            CountryId, MasterCompanyId,
            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
            IsActive, IsDeleted
        )
        VALUES
        (
            @Address1, @Address2, @PostalCode, @StateOrProvince, @City,
            @CountryId, @MasterCompanyId,
            @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
            1, 0
        );

        SET @AddressId = SCOPE_IDENTITY();

        DECLARE @ExistingCheckPaymentId BIGINT;

        SELECT TOP 1 @ExistingCheckPaymentId = cp.CheckPaymentId
        FROM dbo.CheckPayment cp WITH (NOLOCK)
        INNER JOIN dbo.VendorCheckPayment vcp WITH (NOLOCK)
            ON cp.CheckPaymentId = vcp.CheckPaymentId
        WHERE cp.IsPrimayPayment = 1 AND vcp.VendorId = @VendorId;

        IF @ExistingCheckPaymentId IS NOT NULL
        BEGIN
            UPDATE dbo.CheckPayment
            SET IsPrimayPayment = 0,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE CheckPaymentId = @ExistingCheckPaymentId;

            EXEC dbo.USP_ShippingBillingAddressHistory
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId,
                @BillingShippingId = @ExistingCheckPaymentId,
                @AddressType = @CheckPaymentId, 
                @UpdatedBy = @UpdatedBy;
        END

        INSERT INTO dbo.CheckPayment
        (
            SiteName,
            MasterCompanyId,
            IsPrimayPayment,
            CreatedDate,
            UpdatedDate,
            CreatedBy,
            UpdatedBy,
            AddressId,
            IsActive,
            IsDeleted
        )
        VALUES
        (
            @VendorName,
            @MasterCompanyId,
            1,
            GETUTCDATE(),
            GETUTCDATE(),
            @CreatedBy,
            @UpdatedBy,
            @AddressId,
            1,
            0
        );

        SET @NewCheckPaymentId = SCOPE_IDENTITY();

        IF @NewCheckPaymentId > 0
        BEGIN
            INSERT INTO dbo.VendorCheckPayment
            (
                VendorId,
                CheckPaymentId,
                MasterCompanyId,
                CreatedDate,
                UpdatedDate,
                CreatedBy,
                UpdatedBy,
                IsActive,
                IsDeleted
            )
            VALUES
            (
                @VendorId,
                @NewCheckPaymentId,
                @MasterCompanyId,
                GETUTCDATE(),
                GETUTCDATE(),
                @CreatedBy,
                @UpdatedBy,
                1,
                0
            );

            -- Call audit SP
            EXEC dbo.USP_ShippingBillingAddressHistory
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId, 
                @BillingShippingId = @NewCheckPaymentId,
                @AddressType = @CheckPaymentId, 
                @UpdatedBy = @UpdatedBy;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(MAX) = ERROR_MESSAGE();
        DECLARE @ErrorProcedure NVARCHAR(200) = ERROR_PROCEDURE();
        DECLARE @ErrorLine INT = ERROR_LINE();
        DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
        DECLARE @ErrorState INT = ERROR_STATE();
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME();
        EXEC spLogException 
            @DatabaseName = @DatabaseName, 
            @AdhocComments = 'USP_AddVendorPayment', 
            @ProcedureParameters = '', 
            @ApplicationName = 'PAS',
            @ErrorLogID = @ErrorLogID OUTPUT;

        THROW;
    END CATCH
END