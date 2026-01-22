/*************************************************************           
** File:  [USP_AddVendorContact] 
** Author:   Ayushi Patel  
** Description: Add vendor contact (default contact logic handled)
** Purpose:  Replaces EF CreateVendorContact
** Date:   10-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     10-07-2025   Ayushi Patel      Created  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddVendorContact]
    @ContactId BIGINT,
    @VendorId BIGINT,
    @IsDefaultContact BIT,
    @IsRestrictedParty BIT,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(100),
    @UpdatedBy VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @VendorContactId BIGINT;
        DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');

        -- If incoming contact is marked as default, reset any existing default for that vendor
        IF @IsDefaultContact = 1
        BEGIN
            UPDATE dbo.VendorContact
            SET IsDefaultContact = 0,
                UpdatedBy = @UpdatedBy,
                UpdatedDate = GETUTCDATE()
            WHERE VendorId = @VendorId AND IsDefaultContact = 1;

            -- Audit the previous default (if any)
            DECLARE @PreviousVendorContactId BIGINT;
            SELECT TOP 1 @PreviousVendorContactId = VendorContactId 
            FROM VendorContact WITH(NOLOCK) 
            WHERE VendorId = @VendorId AND IsDefaultContact = 0 
            ORDER BY UpdatedDate DESC;

            IF @PreviousVendorContactId IS NOT NULL
            BEGIN
                EXEC dbo.USP_ContactsHistory @VendorId, @VendorModuleId, @PreviousVendorContactId, @UpdatedBy;
            END
        END

        -- Insert new VendorContact
        INSERT INTO dbo.VendorContact (
            ContactId, VendorId, IsDefaultContact, MasterCompanyId,
            CreatedBy, UpdatedBy, CreatedDate, UpdatedDate,
            IsActive, IsDeleted, IsRestrictedParty
        )
        VALUES (
            @ContactId, @VendorId, @IsDefaultContact, @MasterCompanyId,
            @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
            1, 0, @IsRestrictedParty
        );

        SET @VendorContactId = SCOPE_IDENTITY();

        -- Audit the newly inserted contact
        EXEC dbo.USP_ContactsHistory @VendorId, @VendorModuleId, @VendorContactId, @UpdatedBy;

        SELECT 
			VendorContactId,
			VendorId,
			ContactId,
			IsDefaultContact,
			MasterCompanyId,
			CreatedBy,
			UpdatedBy,
			CreatedDate,
			UpdatedDate,
			IsActive,
			IsDeleted,
			IsRestrictedParty
		FROM dbo.VendorContact WITH (NOLOCK)
		WHERE VendorContactId = @VendorContactId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT, @ErrState INT;
        SELECT @ErrMsg = ERROR_MESSAGE(), @ErrSeverity = ERROR_SEVERITY(), @ErrState = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END