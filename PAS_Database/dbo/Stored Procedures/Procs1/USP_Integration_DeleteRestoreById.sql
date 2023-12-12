﻿Create   PROCEDURE [dbo].[USP_Integration_DeleteRestoreById]
@ThirdPartInegrationId bigint,
@IsDeleted bit
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				INSERT INTO ThirdPartInegrationAudit
				SELECT * FROM ThirdPartInegration
				WHERE [ThirdPartInegrationId] = @ThirdPartInegrationId

				IF(@IsDeleted = 'false')
					BEGIN
						UPDATE ThirdPartInegration
						SET IsDeleted = 1
						WHERE [ThirdPartInegrationId] = @ThirdPartInegrationId
					END
				ELSE
					BEGIN
						UPDATE ThirdPartInegration
						SET IsDeleted = 0
						WHERE [ThirdPartInegrationId] = @ThirdPartInegrationId
					END
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_Integration_DeleteRestoreById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ThirdPartInegrationId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END