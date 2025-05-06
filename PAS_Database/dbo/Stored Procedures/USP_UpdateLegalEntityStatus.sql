/*************************************************************           
 ** File:		 [USP_UpdateLegalEntityStatus]           
 ** Author:		 Divyesh Kathiriya
 ** Description: This Stored Procedure Is Used To Update Legal Entity Status.
 ** Purpose:         
 ** Date:   28-April-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	--------------------------------          
    1    28-April-2025		Divyesh Kathiriya	Created
    
 -- EXEC [USP_UpdateLegalEntityStatus] @LegalEntityId=35, @Status=N'Active', @UpdatedBy=N'DANE PERK'
**************************************************************/
CREATE   PROCEDURE [DBO].[USP_UpdateLegalEntityStatus]
@LegalEntityId BIGINT = 0,
@Status VARCHAR(256),
@UpdatedBy VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION

	DECLARE @IsActive BIT;

    IF (LOWER(@Status) = LOWER('Active'))
	BEGIN
        SET @IsActive = 1;
	END
    ELSE
	BEGIN
        SET @IsActive = 0;
	END

	IF(ISNULL(@LegalEntityId, 0) > 0)		
	BEGIN

		UPDATE [DBO].[LegalEntity] 
		SET	[IsActive]=@IsActive, [UpdatedBy] = @UpdatedBy, [UpdatedDate] = GETUTCDATE()
		WHERE LegalEntityId = @LegalEntityId		

	END

	SELECT @LegalEntityId AS LegalEntityId;

	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH
	IF @@trancount > 0  
		PRINT 'ROLLBACK'  
		ROLLBACK TRAN;  
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_UpdateLegalEntityStatus'
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