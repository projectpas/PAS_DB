/*************************************************************           
** File:      [USP_UpdateVendorContactActiveStatus] 
** Author:    Ayushi Patel  
** Description: Updates IsActive status of a Vendor Contact and logs contact history
** Date:      10-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR         Date         Author         Change Description            
** --         ----------   ------------   ------------------------------          
** 1          10-07-2025   Ayushi Patel   Created  
** 2          29-07-2026   Bhargav Saliya Also update VendorContact.IsActive; wrap in transaction; re-raise with THROW; guard VendorModuleId [PN-17467]
**************************************************************/
CREATE PROCEDURE [dbo].[USP_UpdateVendorContactActiveStatus]
    @ContactId  BIGINT,
    @IsActive   BIT,
    @UpdatedBy  VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
        DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM dbo.AttachmentModule WITH (NOLOCK) WHERE Name = 'Vendor');

        DECLARE @VendorId BIGINT, @VendorContactId BIGINT;

        SELECT TOP 1 @VendorId = VendorId, @VendorContactId = VendorContactId
        FROM dbo.VendorContact WHERE ContactId = @ContactId;

        BEGIN TRANSACTION;

            UPDATE dbo.VendorContact SET IsActive = @IsActive,UpdatedDate = GETUTCDATE(),UpdatedBy = @UpdatedBy WHERE ContactId = @ContactId;

            UPDATE dbo.Contact SET IsActive = @IsActive,UpdatedDate = GETUTCDATE(),UpdatedBy = @UpdatedBy WHERE ContactId = @ContactId;

            IF @VendorId IS NOT NULL AND @VendorContactId IS NOT NULL AND @VendorModuleId IS NOT NULL
            BEGIN
                EXEC USP_ContactsHistory @VendorId, @VendorModuleId, @VendorContactId, @UpdatedBy;
            END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH
END