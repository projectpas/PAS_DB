/******************************************************************************************
** File:         [USP_CreateCheckPayment]
** Author:       Ayushi Patel
** Description:  Mirrors EF logic from CreatePaymentinfo controller to handle
**               CheckPayment creation, primary update, and audit history.
** Date:         14-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      14-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateCheckPayment]
    @VendorId BIGINT,
    @ContactTagId BIGINT = NULL,
    @Attention VARCHAR(200),
    @SiteName VARCHAR(100),
    @MasterCompanyId INT,
    @IsPrimayPayment BIT,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100),
    
    @Line1 VARCHAR(100),
    @Line2 VARCHAR(100),
    @Line3 VARCHAR(100),
    @City VARCHAR(100),
    @StateOrProvince VARCHAR(100),
    @PostalCode VARCHAR(50),
    @CountryId INT,

    @OutputCheckPaymentId BIGINT OUTPUT,
	@OutputAddressId BIGINT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRAN;

        DECLARE @CurrentDate DATETIME2 = GETUTCDATE();
        DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
        DECLARE @CheckPaymentTypeId INT = 3;

        INSERT INTO dbo.Address (
            Line1, Line2, Line3, City, StateOrProvince, PostalCode, CountryId,
            MasterCompanyId, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate,
            IsActive, IsDeleted
        )
        VALUES (
            @Line1, @Line2, @Line3, @City, @StateOrProvince, @PostalCode, @CountryId,
            @MasterCompanyId, @CreatedBy, @CurrentDate, @UpdatedBy, @CurrentDate,
            1, 0
        );

        DECLARE @AddressId BIGINT = SCOPE_IDENTITY();
		SET @OutputAddressId = @AddressId;

        IF @IsPrimayPayment = 1
        BEGIN
            DECLARE @OldPrimaryId BIGINT;

            SELECT TOP 1 @OldPrimaryId = cp.CheckPaymentId
            FROM dbo.CheckPayment cp WITH(NOLOCK)
            INNER JOIN dbo.VendorCheckPayment vcp WITH(NOLOCK) ON cp.CheckPaymentId = vcp.CheckPaymentId
            WHERE cp.IsPrimayPayment = 1 AND vcp.VendorId = @VendorId;

            IF @OldPrimaryId IS NOT NULL
            BEGIN
                UPDATE dbo.CheckPayment
                SET IsPrimayPayment = 0,
                    UpdatedBy = @UpdatedBy,
                    UpdatedDate = @CurrentDate
                WHERE CheckPaymentId = @OldPrimaryId;

                EXEC dbo.USP_ShippingBillingAddressHistory
                    @ReferenceId = @VendorId,
                    @ModuleId = @VendorModuleId,
                    @BillingShippingId = @OldPrimaryId,
                    @AddressType = @CheckPaymentTypeId,
                    @UpdatedBy = @UpdatedBy;
            END
        END

        INSERT INTO dbo.CheckPayment (
            ContactTagId, Attention, SiteName, MasterCompanyId,
            IsPrimayPayment, AddressId,
            IsActive, IsDeleted, CreatedBy, CreatedDate, UpdatedBy, UpdatedDate
        )
        VALUES (
            @ContactTagId, @Attention, @SiteName, @MasterCompanyId,
            @IsPrimayPayment, @AddressId,
            1, 0, @CreatedBy, @CurrentDate, @UpdatedBy, @CurrentDate
        );

        SET @OutputCheckPaymentId = SCOPE_IDENTITY();

        EXEC dbo.USP_ShippingBillingAddressHistory
            @ReferenceId = @VendorId,
            @ModuleId = @VendorModuleId,
            @BillingShippingId = @OutputCheckPaymentId,
            @AddressType = @CheckPaymentTypeId,
            @UpdatedBy = @UpdatedBy;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_CreateCheckPayment]',
                @ProcedureParameters VARCHAR(3000) = '',
                @ApplicationName VARCHAR(100) = 'PAS';

        EXEC spLogException
            @DatabaseName = @DatabaseName,
            @AdhocComments = @AdhocComments,
            @ProcedureParameters = @ProcedureParameters,
            @ApplicationName = @ApplicationName,
            @ErrorLogID = @ErrorLogID OUTPUT;

        RAISERROR (
            'Unexpected error occurred. Please contact support with Error ID: %d',
            16, 1, @ErrorLogID
        );
    END CATCH
END