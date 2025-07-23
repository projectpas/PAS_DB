/*********************************************************************************************
** File: [USP_AddOrUpdateVendorDefaultContact]
** Author: Ayushi Patel
** Description: Creates a new vendor default contact or updates existing default contact.
** Purpose: Handles default contact creation/updating for vendor.
** Date: 05-07-2025
**********************************************************************************************
** Change History
**********************************************************************************************
** PR   Date         Author         Change Description
** --   ----------   -------------  ------------------------------------------------------------------
** 1    05-07-2025   Ayushi Patel   Created
[USP_AddOrUpdateVendorDefaultContact] 4863, 'jimin',null,null,null,1,'VICTOR ADMAS','VICTOR ADMAS'
**********************************************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddOrUpdateVendorDefaultContact]
    @VendorId BIGINT,
    @VendorName NVARCHAR(200),
    @VendorEmail NVARCHAR(200),
    @VendorPhone NVARCHAR(100),
    @VendorPhoneExt NVARCHAR(50),
    @MasterCompanyId INT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        DECLARE @ContactId BIGINT;
        DECLARE @VendorContactId BIGINT;
		DECLARE @VendorModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Vendor');
        IF NOT EXISTS (
            SELECT 1 FROM VendorContact VC WITH (NOLOCK)
            WHERE VC.VendorId = @VendorId AND VC.IsDefaultContact = 1
        )
        BEGIN
            INSERT INTO Contact (Email, FirstName, LastName, WorkPhone, WorkPhoneExtn,
                                 MasterCompanyId, IsActive, CreatedDate, UpdatedDate,
                                 CreatedBy, UpdatedBy)
            VALUES (@VendorEmail, @VendorName, 'NA', @VendorPhone, @VendorPhoneExt,
                    @MasterCompanyId, 1, GETUTCDATE(), GETUTCDATE(),
                    @CreatedBy, @UpdatedBy);
			
            SET @ContactId = SCOPE_IDENTITY();
			PRINT @VendorId
			PRINT @ContactId
			print @MasterCompanyId
			
            INSERT INTO VendorContact (VendorId, ContactId,Tag, IsDefaultContact, MasterCompanyId, 
                                        IsActive, IsDeleted, CreatedDate, UpdatedDate,
                                        CreatedBy, UpdatedBy,ContactTagId,Attention,IsRestrictedParty)
            VALUES (@VendorId, @ContactId,'', 1, @MasterCompanyId, 1, 0, GETUTCDATE(), GETUTCDATE(),
                    @CreatedBy, @UpdatedBy,NULL,NULL,NULL);
			
            SET @VendorContactId = SCOPE_IDENTITY();

            EXEC dbo.USP_ContactsHistory
                @ReferenceId = @VendorId,
                @ModuleId = @VendorModuleId, 
                @ContactId = @VendorContactId,
                @UpdatedBy = @UpdatedBy;
        END
        ELSE
        BEGIN
            SELECT TOP 1 @ContactId = VC.ContactId
            FROM VendorContact VC WITH (NOLOCK)
            WHERE VC.VendorId = @VendorId AND VC.IsDefaultContact = 1;

            IF EXISTS (SELECT 1 FROM Contact WHERE ContactId = @ContactId)
            BEGIN
                UPDATE Contact
                SET
                    Email = CASE WHEN ISNULL(Email, '') = '' AND ISNULL(@VendorEmail, '') <> '' THEN @VendorEmail ELSE Email END,
                    WorkPhone = CASE WHEN ISNULL(WorkPhone, '') = '' AND ISNULL(@VendorPhone, '') <> '' THEN @VendorPhone ELSE WorkPhone END,
                    WorkPhoneExtn = CASE WHEN ISNULL(WorkPhoneExtn, '') = '' AND ISNULL(@VendorPhoneExt, '') <> '' THEN @VendorPhoneExt ELSE WorkPhoneExtn END,
                    UpdatedDate = GETUTCDATE(),
                    UpdatedBy = @UpdatedBy
                WHERE ContactId = @ContactId;
				
            END
        END

    END TRY
    BEGIN CATCH
	SELECT
    ERROR_NUMBER() AS ErrorNumber,
    ERROR_STATE() AS ErrorState,
    ERROR_SEVERITY() AS ErrorSeverity,
    ERROR_PROCEDURE() AS ErrorProcedure,
    ERROR_LINE() AS ErrorLine,
    ERROR_MESSAGE() AS ErrorMessage;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'USP_AddOrUpdateVendorDefaultContact' 
            , @ProcedureParameters VARCHAR(3000)  = ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName			= @DatabaseName
                    , @AdhocComments			= @AdhocComments
                    , @ProcedureParameters		= @ProcedureParameters
                    , @ApplicationName			=  @ApplicationName
                    , @ErrorLogID              = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
    END CATCH
END