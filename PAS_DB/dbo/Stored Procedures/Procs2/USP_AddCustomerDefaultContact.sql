/*************************************************************           
** File:  [USP_AddCustomerDefaultContact] 
** Author:   Ayushi Patel  
** Description: Add Customer Default Contact
** Purpose:  
** Date:   07-07-2025  
**************************************************************           
** Change History           
**************************************************************           
** PR     Date         Author           Change Description            
** --    --------     -------           -------------------------------          
** 1     07-07-2025   Ayushi Patel      Created  

exec [USP_AddCustomerDefaultContact] 4307,ax,'','','',1,1,'VICTOR ADMAS','VICTOR ADMAS'
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_AddCustomerDefaultContact]
    @CustomerId BIGINT,
    @CustomerName NVARCHAR(100),
    @CustomerEmail NVARCHAR(100),
    @CustomerPhone NVARCHAR(50),
    @CustomerPhoneExt NVARCHAR(50),
    @MasterCompanyId BIGINT,
    @IsActive BIT,
    @CreatedBy NVARCHAR(100),
    @UpdatedBy NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        DECLARE @ContactId BIGINT = NULL;
        DECLARE @CustomerContactId BIGINT = NULL;
		DECLARE @CustomerModuleId INT = (SELECT TOP 1 AttachmentModuleId FROM DBO.AttachmentModule WITH(NOLOCK) WHERE Name = 'Customer');
        
		IF NOT EXISTS (
            SELECT 1 FROM CustomerContact WITH (NOLOCK)
            WHERE CustomerId = @CustomerId
        )
        BEGIN
            INSERT INTO Contact (
                FirstName, LastName, Email, Tag, WorkPhone, WorkPhoneExtn,
                MasterCompanyId, IsActive, CreatedDate, UpdatedDate, CreatedBy, UpdatedBy
            )
            VALUES (
                @CustomerName, 'NA', @CustomerEmail, 'NA', @CustomerPhone, @CustomerPhoneExt,
                @MasterCompanyId, 1, GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy
            );

            SET @ContactId = SCOPE_IDENTITY();

            INSERT INTO CustomerContact (
                ContactId, CustomerId, IsDefaultContact, MasterCompanyId, IsActive, IsDeleted,
                CreatedDate, UpdatedDate, CreatedBy, UpdatedBy
            )
            VALUES (
                @ContactId, @CustomerId, 1, @MasterCompanyId, @IsActive, 0,
                GETUTCDATE(), GETUTCDATE(), @CreatedBy, @UpdatedBy
            );

            SET @CustomerContactId = SCOPE_IDENTITY();

            EXEC dbo.USP_ContactsHistory @CustomerId, @CustomerModuleId, @CustomerContactId, @UpdatedBy;
        END
        ELSE
        BEGIN
            DECLARE @DefaultContactId BIGINT;

            SELECT TOP 1 @DefaultContactId = cc.ContactId
            FROM CustomerContact cc WITH (NOLOCK)
            WHERE cc.CustomerId = @CustomerId AND cc.IsDefaultContact = 1;

            IF @DefaultContactId IS NOT NULL
            BEGIN
                DECLARE @HasChanges BIT = 0;

                UPDATE Contact
                SET 
                    Email = CASE WHEN (ISNULL(Email, '') = '' AND ISNULL(@CustomerEmail, '') <> '') THEN @CustomerEmail ELSE Email END,
                    WorkPhone = CASE WHEN (ISNULL(WorkPhone, '') = '' AND ISNULL(@CustomerPhone, '') <> '') THEN @CustomerPhone ELSE WorkPhone END,
                    WorkPhoneExtn = CASE WHEN (ISNULL(WorkPhoneExtn, '') = '' AND ISNULL(@CustomerPhoneExt, '') <> '') THEN @CustomerPhoneExt ELSE WorkPhoneExtn END,
                    UpdatedDate = GETUTCDATE(),
                    UpdatedBy = @UpdatedBy
                WHERE ContactId = @DefaultContactId
                  AND (
                      (ISNULL(Email, '') = '' AND ISNULL(@CustomerEmail, '') <> '') OR
                      (ISNULL(WorkPhone, '') = '' AND ISNULL(@CustomerPhone, '') <> '') OR
                      (ISNULL(WorkPhoneExtn, '') = '' AND ISNULL(@CustomerPhoneExt, '') <> '')
                  );
            END
        END
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;
        SELECT 
            @ErrorMessage = ERROR_MESSAGE(),
            @ErrorSeverity = ERROR_SEVERITY(),
            @ErrorState = ERROR_STATE();
        RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);
    END CATCH
END