/*************************************************************           
** File:      [USP_UpdateVendorContactAndContact] 
** Author:    Ayushi Patel  
** Description: Update Vendor Contact And Contact
** Date:      14-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author         Change Description            
** --     ----------   ------------   ------------------------------          
** 1      14-07-2025   Ayushi Patel   Created  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_UpdateVendorContactAndContact]
    @ContactId BIGINT,
    @ContactTitle VARCHAR(100) = NULL,
    @AlternatePhone VARCHAR(50) = NULL,
    @ContactTagId BIGINT = NULL,
    @Attention NVARCHAR(200) = NULL,
    @Email VARCHAR(256) = NULL,
    @Prefix VARCHAR(50) = NULL,
    @Suffix VARCHAR(50) = NULL,
    @Fax VARCHAR(50) = NULL,
    @FirstName VARCHAR(100) = NULL,
    @LastName VARCHAR(100) = NULL,
    @MiddleName VARCHAR(100) = NULL,
    @MobilePhone VARCHAR(50) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @WorkPhone VARCHAR(50) = NULL,
    @WebsiteURL NVARCHAR(200) = NULL,
    @MasterCompanyId INT,
    @IsActive BIT,
    @UpdatedBy VARCHAR(100),
    @WorkPhoneExtn VARCHAR(50) = NULL,
    @Tag VARCHAR(100) = NULL,
    @IsDefaultContact BIT,
    @IsRestrictedParty BIT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @VendorContactId BIGINT, @VendorId BIGINT;
		DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
        
		UPDATE dbo.Contact
        SET
            ContactTitle = @ContactTitle,
            AlternatePhone = @AlternatePhone,
            ContactTagId = @ContactTagId,
            Attention = @Attention,
            Email = @Email,
            Prefix = @Prefix,
            Suffix = @Suffix,
            Fax = @Fax,
            FirstName = @FirstName,
            LastName = @LastName,
            MiddleName = @MiddleName,
            MobilePhone = @MobilePhone,
            Notes = @Notes,
            WorkPhone = @WorkPhone,
            WebsiteURL = @WebsiteURL,
            MasterCompanyId = @MasterCompanyId,
            IsActive = @IsActive,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy,
            WorkPhoneExtn = @WorkPhoneExtn,
            Tag = @Tag
        WHERE ContactId = @ContactId;

        SELECT TOP 1
            @VendorContactId = VendorContactId,
            @VendorId = VendorId
        FROM dbo.VendorContact WITH (NOLOCK)
        WHERE ContactId = @ContactId;

        IF (@IsDefaultContact = 1)
        BEGIN
            UPDATE dbo.VendorContact
            SET IsDefaultContact = 0,
                UpdatedDate = GETUTCDATE(),
                UpdatedBy = @UpdatedBy
            WHERE VendorId = @VendorId
              AND IsDefaultContact = 1
              AND ContactId <> @ContactId;

            EXEC USP_ContactsHistory @VendorId, @VendorModuleId, @VendorContactId, @UpdatedBy;
        END

        UPDATE dbo.VendorContact
        SET
            IsDefaultContact = @IsDefaultContact,
            IsRestrictedParty = @IsRestrictedParty,
            UpdatedDate = GETUTCDATE(),
            UpdatedBy = @UpdatedBy
        WHERE VendorContactId = @VendorContactId;

        EXEC USP_ContactsHistory @VendorId, @VendorModuleId, @VendorContactId, @UpdatedBy;

        SELECT 
            VendorContactId,
            VendorId,
            ContactId,
            IsDefaultContact,
            IsRestrictedParty,
            MasterCompanyId,
            CreatedBy,
            CreatedDate,
            UpdatedBy,
            UpdatedDate,
            ISNULL(IsActive,0) AS IsActive,
            ISNULL(IsDeleted,0) AS IsDeleted
        FROM dbo.VendorContact WITH (NOLOCK)
        WHERE VendorContactId = @VendorContactId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR (@ErrorMessage, 16, 1);
    END CATCH
END