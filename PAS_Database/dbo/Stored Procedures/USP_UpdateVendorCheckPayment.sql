/******************************************************************************************
** File:         [USP_UpdateVendorCheckPayment]
** Author:       Ayushi Patel
** Description:  Updates CheckPayment and Address records and manages primary flag logic.
** Date:         14-07-2025
*******************************************************************************************
** Change History
*******************************************************************************************
** PR     Date         Author         Change Description
** --     ----------   ------------   -----------------------------------------------------
** 1      14-07-2025   Ayushi Patel   Created
*******************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorCheckPayment]
    @AddressId BIGINT,
    @VendorId BIGINT,
    @CheckPaymentId BIGINT,
    @SiteName VARCHAR(100),
    @ContactTagId BIGINT = NULL,
    @Attention VARCHAR(250),
    @MasterCompanyId INT,
    @IsPrimayPayment BIT,
    @AddressLine1 VARCHAR(100),
    @AddressLine2 VARCHAR(100),
    @AddressLine3 VARCHAR(100),
    @City VARCHAR(100),
    @StateOrProvince VARCHAR(100),
    @PostalCode VARCHAR(50),
    @CountryId INT,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        BEGIN TRANSACTION;
		DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
        DECLARE @CheckPaymentTypeId INT = 3;
        
        UPDATE dbo.Address
        SET
            Line1 = @AddressLine1,
            Line2 = @AddressLine2,
            Line3 = @AddressLine3,
            City = @City,
            StateOrProvince = @StateOrProvince,
            PostalCode = @PostalCode,
            CountryId = @CountryId,
            MasterCompanyId = @MasterCompanyId,
            CreatedBy = @CreatedBy,
            UpdatedBy = @UpdatedBy,
            CreatedDate = GETUTCDATE(),
            UpdatedDate = GETUTCDATE()
        WHERE AddressId = @AddressId;

       
        IF @IsPrimayPayment = 1
        BEGIN
            DECLARE @OldPrimaryId BIGINT;

            SELECT TOP 1 @OldPrimaryId = cp.CheckPaymentId
            FROM dbo.CheckPayment cp WITH(NOLOCK)
            JOIN dbo.VendorCheckPayment vcp WITH(NOLOCK) ON cp.CheckPaymentId = vcp.CheckPaymentId
            WHERE cp.IsPrimayPayment = 1
              AND vcp.VendorId = @VendorId
              AND cp.CheckPaymentId <> @CheckPaymentId;

            IF @OldPrimaryId IS NOT NULL
            BEGIN
                UPDATE dbo.CheckPayment
                SET IsPrimayPayment = 0,
                    UpdatedBy = @UpdatedBy,
                    UpdatedDate = GETUTCDATE()
                WHERE CheckPaymentId = @OldPrimaryId;

                
                EXEC dbo.USP_ShippingBillingAddressHistory
                    @ReferenceId = @VendorId,
                    @ModuleId = @VendorModuleId, 
                    @BillingShippingId = @OldPrimaryId,
                    @AddressType = @CheckPaymentTypeId,
                    @UpdatedBy = @UpdatedBy;
            END
        END

        
        UPDATE dbo.CheckPayment
        SET
            SiteName = @SiteName,
            ContactTagId = @ContactTagId,
            Attention = @Attention,
            MasterCompanyId = @MasterCompanyId,
            IsPrimayPayment = @IsPrimayPayment,
            CreatedBy = @CreatedBy,
            UpdatedBy = @UpdatedBy,
            UpdatedDate = GETUTCDATE()
        WHERE AddressId = @AddressId;

        
        EXEC dbo.USP_ShippingBillingAddressHistory
            @ReferenceId = @VendorId,
            @ModuleId = @VendorModuleId,
            @BillingShippingId = @CheckPaymentId,
            @AddressType = @CheckPaymentTypeId,
            @UpdatedBy = @UpdatedBy;

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK;

        DECLARE @ErrorLogID INT,
                @DatabaseName VARCHAR(100) = DB_NAME(),
                @AdhocComments VARCHAR(150) = '[USP_UpdateVendorCheckPayment]',
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