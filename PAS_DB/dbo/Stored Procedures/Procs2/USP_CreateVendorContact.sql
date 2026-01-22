/*************************************************************           
** File:  [USP_CreateVendorContact] 
** Author:   Ayushi Patel  
** Description: Create or Update Vendor Contact
** Purpose:  This SP creates a new contact for a vendor (same as EF: CreateContact)
** Date:   10-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     10-07-2025   Ayushi Patel      Created  
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateVendorContact]
    @ContactTitle VARCHAR(30) = NULL,
    @AlternatePhone VARCHAR(20) = NULL,
    @ContactTagId BIGINT = NULL,
    @Attention VARCHAR(250) = NULL,
    @Email VARCHAR(200) = NULL,
    @Prefix VARCHAR(20) = NULL,
    @Suffix VARCHAR(20) = NULL,
    @Fax VARCHAR(20) = NULL,
    @FirstName VARCHAR(100),
    @LastName VARCHAR(30),
    @MiddleName VARCHAR(30) = NULL,
    @MobilePhone VARCHAR(20) = NULL,
    @Notes NVARCHAR(MAX) = NULL,
    @WorkPhone VARCHAR(20) = NULL,
    @WebsiteURL VARCHAR(200) = NULL,
    @MasterCompanyId INT,
    @CreatedBy VARCHAR(256),
    @UpdatedBy VARCHAR(256),
    @WorkPhoneExtn VARCHAR(20) = NULL,
    @Tag VARCHAR(255) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ContactId BIGINT;

        INSERT INTO dbo.Contact (
            ContactTitle, AlternatePhone, ContactTagId, Attention,
            Email, Prefix, Suffix, Fax, FirstName, LastName, MiddleName,
            MobilePhone, Notes, WorkPhone, WebsiteURL, MasterCompanyId,
            IsActive, IsDeleted, CreatedDate, UpdatedDate, CreatedBy,
            UpdatedBy, WorkPhoneExtn, Tag
        )
        VALUES (
            @ContactTitle, @AlternatePhone, @ContactTagId, @Attention,
            @Email, @Prefix, @Suffix, @Fax, @FirstName, @LastName, @MiddleName,
            @MobilePhone, @Notes, @WorkPhone, @WebsiteURL, @MasterCompanyId,
            1, 0, GETUTCDATE(), GETUTCDATE(), @CreatedBy,
            @UpdatedBy, @WorkPhoneExtn, @Tag
        );

        SET @ContactId = SCOPE_IDENTITY();

        SELECT *
        FROM dbo.Contact WITH(NOLOCK)
        WHERE ContactId = @ContactId;
    END TRY
    BEGIN CATCH
        DECLARE @ErrMsg NVARCHAR(4000), @ErrSeverity INT, @ErrState INT;
        SELECT 
            @ErrMsg = ERROR_MESSAGE(),
            @ErrSeverity = ERROR_SEVERITY(),
            @ErrState = ERROR_STATE();
        RAISERROR(@ErrMsg, @ErrSeverity, @ErrState);
    END CATCH
END