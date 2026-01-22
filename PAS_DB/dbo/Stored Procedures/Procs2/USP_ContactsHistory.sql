/*************************************************************            
** File:		[USP_ContactsHistory]        
** Author:		Divyesh Kathriya
** Description: Logs audit history for contact across modules: Customer, Vendor, Legal Entity.
** Purpose:		Called by multiple modules to capture contact changes for audit purposes.
** Date:		20-MAY-2025     
        
** PARAMETERS: 
    @ReferenceId BIGINT,
    @ModuleId INT,
    @ContactId BIGINT,   
    @UpdatedBy VARCHAR(256)

** RETURN VALUE: None
**************************************************************           
** Change History           
**************************************************************           
** PR   Date			Author				Change Description            
** --   --------		-------				--------------------------------          
   1    20-MAY-2025    Divyesh Kathiriya	Created

  --EXEC [DBO].[USP_ContactsHistory] 43, 30, 48 , 'DANE PERK'
************************************************************************/
CREATE   PROCEDURE [DBO].[USP_ContactsHistory]
@ReferenceId BIGINT,
@ModuleId INT,
@ContactId BIGINT,   
@UpdatedBy VARCHAR(256)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    BEGIN TRY	
	BEGIN TRANSACTION
		
		DECLARE @ContId BIGINT = 0;
		DECLARE @FirstName VARCHAR(100),
                @LastName VARCHAR(30),
                @MiddleName VARCHAR(30),
                @ContactTitle VARCHAR(30),
                @WorkPhone VARCHAR(20),
                @MobilePhone VARCHAR(20),
                @ContactTagId BIGINT,
                @Attention VARCHAR(250),
                @Prefix VARCHAR(20),
                @Suffix VARCHAR(20),
                @AlternatePhone VARCHAR(20),
                @WorkPhoneExtn VARCHAR(20),
                @Fax VARCHAR(20),
                @Email VARCHAR(200),
                @WebsiteURL VARCHAR(200),
				@Notes NVARCHAR(MAX),
                @Tag VARCHAR(255),                
				@AuditContactId BIGINT,
                @IsDefaultContact BIT,
                @IsActive BIT,
                @IsDeleted BIT,
                @MasterCompanyId INT,
				@CreatedBy VARCHAR(256),
                @CreatedDate DATETIME2;

		DECLARE @CustomerModuleId INT;
		DECLARE @VendorModuleId INT;
		DECLARE @LegalEntityModuleId INT;

		SELECT @CustomerModuleId = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'Customer';
		SELECT @VendorModuleId = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'Vendor';
		SELECT @LegalEntityModuleId = [AttachmentModuleId] FROM [DBO].[AttachmentModule] WITH(NOLOCK) WHERE [Name] = 'LegalEntity';
  

        IF (@ModuleId = @CustomerModuleId)
        BEGIN
            SELECT 
                @AuditContactId = [CustomerContactId],
                @IsDefaultContact = ISNULL([IsDefaultContact], 0),
                @IsActive = ISNULL([IsActive], 1),
                @IsDeleted = ISNULL([IsDeleted], 0),
                @MasterCompanyId = [MasterCompanyId],
				@CreatedBy = [CreatedBy],
                @CreatedDate = [CreatedDate],				 
                @ContId = [ContactId]
            FROM [DBO].[CustomerContact] WITH(NOLOCK)
            WHERE [CustomerContactId] = @ContactId;
        END
        ELSE IF (@ModuleId = @VendorModuleId)
        BEGIN
			SELECT TOP 1 @IsActive = CASE WHEN C.[ContactId] IS NOT NULL THEN C.[IsActive] ELSE VC.[IsActive] END
			FROM [DBO].[VendorContact] VC WITH(NOLOCK)
			LEFT JOIN [DBO].[Contact] C WITH(NOLOCK) ON C.[ContactId] = VC.[ContactId]
			WHERE VC.[VendorContactId] = @ContactId;		

            SELECT 
                @AuditContactId = [VendorContactId],
                @IsDefaultContact = ISNULL([IsDefaultContact], 0),
                @IsDeleted = ISNULL([IsDeleted], 0),
                @MasterCompanyId = [MasterCompanyId],
				@CreatedBy = [CreatedBy],
                @CreatedDate = [CreatedDate],
                @ContId = [ContactId]
            FROM [DBO].[VendorContact] WITH(NOLOCK)
            WHERE [VendorContactId] = @ContactId;            
        END
        ELSE IF (@ModuleId = @LegalEntityModuleId)
        BEGIN
            SELECT 
                @AuditContactId = [LegalEntityContactId],
                @IsDefaultContact = ISNULL([IsDefaultContact], 0),
                @IsActive = ISNULL([IsActive], 1),
				@MasterCompanyId = [MasterCompanyId],
                @IsDeleted = ISNULL([IsDeleted], 0),
				@CreatedBy = [CreatedBy],
                @CreatedDate = [CreatedDate],
				@ContId = [ContactId]
            FROM [DBO].[LegalEntityContact] WITH(NOLOCK)
            WHERE [LegalEntityContactId] = @ContactId;
        END

        SELECT 
            @FirstName = [FirstName],
            @LastName = [LastName],
            @MiddleName = [MiddleName],
            @ContactTitle = [ContactTitle],
            @WorkPhone = [WorkPhone],
            @MobilePhone = [MobilePhone],
            @ContactTagId = [ContactTagId],
            @Attention = [Attention],
            @Prefix = [Prefix],
            @Suffix = [Suffix],
            @AlternatePhone = [AlternatePhone],
            @WorkPhoneExtn = [WorkPhoneExtn],
            @Fax = [Fax],
            @Email = [Email],
            @WebsiteURL = [WebsiteURL],
            @Notes = [Notes],
            @Tag = [Tag]
        FROM [DBO].[Contact] WITH(NOLOCK)
        WHERE [ContactId] = @ContId;

        INSERT INTO [DBO].[ContactAudit]
        (
            [ModuleId],[ReferenceId], [ContactId], [IsDefaultContact],
			[Prefix], [FirstName], [LastName],[MiddleName], [Suffix],
			[ContactTitle], [WorkPhone], [WorkPhoneExtn], [MobilePhone],
			[AlternatePhone], [Fax], [Email], [WebsiteURL], [Notes],
			[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate],
			[IsActive], [Tag], [IsDeleted], [ContactTagId], [Attention]  
        )
        VALUES
        (
            @ModuleId, @ReferenceId, @AuditContactId, @IsDefaultContact, 
			@Prefix, @FirstName, @LastName, @MiddleName, @Suffix,
			@ContactTitle, @WorkPhone, @WorkPhoneExtn, @MobilePhone,
			@AlternatePhone, @Fax, @Email, @WebsiteURL, @Notes,
			@MasterCompanyId, @CreatedBy, @UpdatedBy, @CreatedDate, GETUTCDATE(),
			@IsActive, @Tag, @IsDeleted, @ContactTagId, @Attention 
        );       

    COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0 		
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ContactsHistory'
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