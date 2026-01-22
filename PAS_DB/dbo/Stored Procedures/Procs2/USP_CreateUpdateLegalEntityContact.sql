/*************************************************************           
 ** File:		 [USP_CreateUpdateLegalEntityContact]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Create or Update LegalEntity Contact.
 ** Purpose:         
 ** Date:   22-May-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    22-May-2025		Divyesh Kathiriya	Created
	2	 23-May-2025		Divyesh Kathiriya	Add Update Functionality of LegalEntity Contact.  	
    
 -- EXEC [USP_CreateUpdateLegalEntityContact] @ContactId=0,@Prefix=N'Mr.',@FirstName=N'First Name',@LastName=N'Last Name ',@MiddleName=N'Middle Name',@Suffix=N'III',
 @ContactTitle=N'Title',@WorkPhone=N'123-456',@WorkPhoneExtn=N'079',@MobilePhone=N'89455621',@AlternatePhone=N'123456879',@Fax=N'456-1456',@Email=N'email@email.com',
 @WebsiteURL=N'www.web.com',@Notes=N'<p>memo</p>',@MasterCompanyId=1,@CreatedBy=N'DANE PERK',@UpdatedBy=N'DANE PERK',@Tag=N'ACCOUNTS PAYABLES',@ContactTagId=9,
 @Attention=N'Attention',@LegalEntityId=41,@IsDefaultContact=1,@IsActive=1
**************************************************************/
Create   PROCEDURE [DBO].[USP_CreateUpdateLegalEntityContact]
@ContactId BIGINT,
@Prefix VARCHAR(20) = NULL,
@FirstName VARCHAR(100),
@LastName VARCHAR(30),
@MiddleName VARCHAR(30) = NULL,
@Suffix VARCHAR(20) = NULL,
@ContactTitle VARCHAR(30) = NULL,
@WorkPhone VARCHAR(20) = NULL,
@WorkPhoneExtn VARCHAR(20) = NULL,
@MobilePhone VARCHAR(20) = NULL,
@AlternatePhone VARCHAR(20) = NULL,
@Fax VARCHAR(20) = NULL,
@Email VARCHAR(200) = NULL,
@WebsiteURL VARCHAR(200) = NULL,
@Notes NVARCHAR(MAX) = NULL,
@MasterCompanyId INT,
@CreatedBy VARCHAR(256),
@UpdatedBy VARCHAR(256),
@Tag VARCHAR(255) = NULL,
@ContactTagId BIGINT = NULL,
@Attention VARCHAR(250) = NULL,
@LegalEntityId BIGINT,
@IsDefaultContact BIT = 0,
@IsActive BIT = 1
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	
	DECLARE @LegalEntityModuleId INT;
	DECLARE @LegalEntityContactId BIGINT;
	
	SELECT @LegalEntityModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';

	IF(@ContactId = 0)
	BEGIN
		--INSERT INTO [DBO].[CONTACT]
		INSERT INTO [DBO].[Contact] (
			[Prefix], [FirstName], [LastName], [MiddleName], [Suffix], [ContactTitle], [WorkPhone],
			[WorkPhoneExtn], [MobilePhone], [AlternatePhone], [Fax], [Email], [WebsiteURL],
			[Notes], [MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
			[IsActive], [Tag], [IsDeleted], [ContactTagId], [Attention])
		VALUES(
			@Prefix, @FirstName, @LastName, @MiddleName, @Suffix, @ContactTitle, @WorkPhone,
			@WorkPhoneExtn, @MobilePhone, @AlternatePhone, @Fax, @Email, @WebsiteURL,
			@Notes, @MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
			1, @Tag, 0, @ContactTagId, @Attention);

		SET @ContactId = SCOPE_IDENTITY();
		

		--IF NEW DEFAULT, RESET OLD DEFAULT TO NO-DEFAULT
		IF(ISNULL(@IsDefaultContact, 0) = 1)
		BEGIN
			SELECT @LegalEntityContactId = [LegalEntityContactId] FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsDefaultContact] = 1;
			
			IF (@LegalEntityContactId IS NOT NULL)
			BEGIN
				UPDATE [DBO].[LegalEntityContact]
				SET    [IsDefaultContact] = 0,
					   [UpdatedDate] = GETUTCDATE(),
					   [Tag] = @Tag,
					   [UpdatedBy] = @UpdatedBy
				WHERE [LegalEntityId] = @LegalEntityId AND [IsDefaultContact] = 1;

				EXEC [DBO].[USP_ContactsHistory] @LegalEntityId, @LegalEntityModuleId, @LegalEntityContactId, @UpdatedBy;
			END
		END
		ELSE
		BEGIN
			IF NOT EXISTS (SELECT 1 FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsDefaultContact] = 1)
			BEGIN
				SET @IsDefaultContact = 1;
			END
		END

		--INSERT INTO [DBO].[LEGALENTITYCONTACT]
		INSERT INTO [DBO].[LegalEntityContact] (
			[LegalEntityId], [ContactId], [IsDefaultContact], [Tag],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
			[IsActive], [IsDeleted])
		VALUES (
			@LegalEntityId, @ContactId, @IsDefaultContact, @Tag,
			@MasterCompanyId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(),
			1, 0);

		SET @LegalEntityContactId = SCOPE_IDENTITY();

		EXEC [DBO].[USP_ContactsHistory] @LegalEntityId, @LegalEntityModuleId, @LegalEntityContactId, @UpdatedBy;

		SELECT @Contactid AS Contactid, @IsDefaultContact AS IsDefaultContact;		
	END
	ELSE
	BEGIN
		--UPDATE [DBO].[CONTACT]
		UPDATE [DBO].[Contact]
        SET [Prefix] = @Prefix, [FirstName] = @FirstName, [LastName] = @LastName,
            [MiddleName] = @MiddleName, [Suffix] = @Suffix, [ContactTitle] = @ContactTitle,
            [WorkPhone] = @WorkPhone, [WorkPhoneExtn] = @WorkPhoneExtn,
            [MobilePhone] = @MobilePhone, [AlternatePhone] = @AlternatePhone,
            [Fax] = @Fax, [Email] = @Email, [WebsiteURL] = @WebsiteURL, [Notes] = @Notes,
            [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE(),
            [IsActive] = @IsActive, [Tag] = @Tag, [ContactTagId] = @ContactTagId, [Attention] = @Attention
        WHERE [ContactId] = @ContactId;

		--ONLY RESET DEFAULT IF THE DEFAULT IS CURRENTLY ASSIGNED TO A DIFFERENT CONTACTID
		IF(ISNULL(@IsDefaultContact, 0) = 1)
		BEGIN
			SELECT @LegalEntityContactId = [LegalEntityContactId] FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [IsDefaultContact] = 1;
			
			IF (@LegalEntityContactId IS NOT NULL AND EXISTS (SELECT 1 FROM [DBO].[LegalEntityContact] WITH(NOLOCK)	WHERE [LegalEntityContactId] = @LegalEntityContactId AND [ContactId] != @ContactId))
			BEGIN
				UPDATE [DBO].[LegalEntityContact]
				SET    [IsDefaultContact] = 0,
					   [UpdatedDate] = GETUTCDATE(),					   
					   [UpdatedBy] = @UpdatedBy
				WHERE [LegalEntityId] = @LegalEntityId AND [IsDefaultContact] = 1;

				EXEC [DBO].[USP_ContactsHistory] @LegalEntityId, @LegalEntityModuleId, @LegalEntityContactId, @UpdatedBy;
			END
		END

		--UPDATE [DBO].[LegalEntityContact]
		UPDATE [DBO].[LegalEntityContact]
        SET [IsDefaultContact] = @IsDefaultContact,            
            [UpdatedBy] = @UpdatedBy,
            [UpdatedDate] = GETUTCDATE()            
        WHERE [LegalEntityId] = @LegalEntityId AND [ContactId] = @ContactId;

        SELECT @LegalEntityContactId = [LegalEntityContactId] FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND [ContactId] = @ContactId;

		EXEC [DBO].[USP_ContactsHistory] @LegalEntityId, @LegalEntityModuleId, @LegalEntityContactId, @UpdatedBy;

		SELECT @Contactid AS Contactid, @IsDefaultContact AS IsDefaultContact;	
	END
	
	COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateUpdateLegalEntityContact'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

		RETURN (1); 
	END CATCH

END