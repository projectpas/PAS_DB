/*************************************************************           
** File:      [USP_UpdateVendorContactActiveStatus] 
** Author:    Ayushi Patel  
** Description: Updates IsActive status of a Vendor Contact and logs contact history
** Date:      10-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author         Change Description            
** --     ----------   ------------   ------------------------------          
** 1      10-07-2025   Ayushi Patel   Created  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorContactActiveStatus]
    @ContactId BIGINT,
    @IsActive BIT,
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY
	DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
        UPDATE dbo.Contact
        SET 
            IsActive = @IsActive,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE ContactId = @ContactId;

        DECLARE @VendorId BIGINT, @VendorContactId BIGINT;

        SELECT TOP 1 
            @VendorId = VendorId,
            @VendorContactId = VendorContactId
        FROM VendorContact WITH(NOLOCK)
        WHERE ContactId = @ContactId;

        IF @VendorId IS NOT NULL AND @VendorContactId IS NOT NULL
        BEGIN
            EXEC USP_ContactsHistory @VendorId, @VendorModuleId, @VendorContactId, @UpdatedBy;
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT;
        SELECT 
            @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY();
        RAISERROR(@ErrMsg, @ErrSeverity, 1);
    END CATCH
END