
--EXEC USP_GetCageCode_ByLegalEntityId 1, 1
CREATE   PROCEDURE [dbo].[USP_GetCageCode_ByLegalEntityId]
	@LegalEntityId bigint,
	@ThirdPartInegrationId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					CASE WHEN (SELECT COUNT(1) FROM [DBO].[ThirdPartInegration] WITH (NOLOCK) WHERE [LegalEntityId] = @LegalEntityId AND IntegrationIds = @ThirdPartInegrationId) > 0 THEN 1 ELSE 0 END AS IsExist, 
					t.LegalEntityId,
					t.CageCode
				FROM [DBO].[LegalEntity] t WITH (NOLOCK) 
				WHERE t.[LegalEntityId] = @LegalEntityId; 
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCageCode_ByLegalEntityId' 
              , @ProcedureParameters VARCHAR(3000)  = '@LegalEntityId = '''+ ISNULL(@LegalEntityId, '') + ''
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