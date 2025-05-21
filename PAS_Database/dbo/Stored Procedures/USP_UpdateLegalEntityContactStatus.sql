/*************************************************************           
 ** File:		 [USP_UpdateLegalEntityContactStatus]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update Legal Entity Contact Status.
 ** Purpose:         
 ** Date:   19-MAY-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    19-MAY-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_UpdateLegalEntityContactStatus] @Contactid=35, @Status=N'Active', @UpdatedBy=N'DANE PERK'
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_UpdateLegalEntityContactStatus]
@Contactid BIGINT = 0,
@Status VARCHAR(256),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @IsActive BIT;
	DECLARE @LegalEntityModuleId INT;
	DECLARE @LegalEntityId BIGINT;
	DECLARE @LegalEntityContactId BIGINT;	

	SELECT @LegalEntityModuleId = [ModuleId] FROM [DBO].[Module] WITH(NOLOCK) WHERE [ModuleName] = 'LegalEntity';
	SELECT @LegalEntityId = [LegalEntityId] FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [ContactId] = @ContactId;
    SELECT @LegalEntityContactId = [LegalEntityContactId] FROM [DBO].[LegalEntityContact] WITH(NOLOCK) WHERE [ContactId] = @ContactId;

	IF (LOWER(@Status) = LOWER('Active'))
	BEGIN
        SET @IsActive = 1;
	END
    ELSE
	BEGIN
        SET @IsActive = 0;
	END

	IF(ISNULL(@Contactid, 0) > 0)		
	BEGIN
		IF EXISTS (SELECT 1 FROM [DBO].[Contact] WITH(NOLOCK) WHERE [ContactId] = @ContactId)
		BEGIN
			UPDATE [DBO].[Contact] 
			SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [ContactId] = @Contactid
		
			UPDATE [DBO].[LegalEntityContact] 
			SET	[IsActive] = @IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
			WHERE [ContactId] = @Contactid	

			EXEC [DBO].[USP_ContactsHistory] @LegalEntityId, @LegalEntityModuleId, @LegalEntityContactId, @UpdatedBy;
		END
	END

	SELECT @Contactid AS Contactid;

	COMMIT TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0		
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateLegalEntityContactStatus'
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