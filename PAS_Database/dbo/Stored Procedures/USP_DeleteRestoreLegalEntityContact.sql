/*************************************************************           
 ** File:		 [USP_DeleteRestoreLegalEntityContact]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Delete Or Restore Legal Entity Contact.
 ** Purpose:         
 ** Date:   21-MAY-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    21-May-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_DeleteRestoreLegalEntityContact] @ContactId=13118, @UpdatedBy=N'DANE PERK', @IsDeleted=1
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_DeleteRestoreLegalEntityContact]
@ContactId BIGINT,
@UpdatedBy VARCHAR(256),
@IsDeleted BIT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	
		DECLARE @LegalEntityModuleId INT;
		DECLARE @LegalEntityId BIGINT;
		DECLARE @LegalEntityContactId BIGINT;	

		SELECT @LegalEntityModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';
		SELECT @LegalEntityId = [LegalEntityId] FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [ContactId] = @ContactId;
		SELECT @LegalEntityContactId = [LegalEntityContactId] FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [ContactId] = @ContactId;
		
		IF(ISNULL(@IsDeleted, 0) = 1)
		BEGIN
			IF EXISTS (SELECT 1 FROM [DBO].[Contact] WITH(NOLOCK) WHERE [ContactId] = @ContactId)
			BEGIN
				UPDATE [DBO].[Contact] 
				SET	[IsDeleted] = @IsDeleted, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
				WHERE [ContactId] = @Contactid
		
				UPDATE [DBO].[LegalEntityContact] 
				SET	[IsDeleted] = @IsDeleted, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
				WHERE [ContactId] = @Contactid	

				EXEC [DBO].[USP_ContactsHistory] @LegalEntityId, @LegalEntityModuleId, @LegalEntityContactId, @UpdatedBy;
			END
		END		
		
		SELECT @Contactid AS Contactid;

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_DeleteRestoreLegalEntityContact'
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