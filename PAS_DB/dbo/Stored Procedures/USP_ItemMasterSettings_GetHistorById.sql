Create   PROCEDURE [dbo].[USP_ItemMasterSettings_GetHistorById]
@ItemMasterSettingsId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					t.[ItemMasterSettingsId],
					t.[GLAccountId],
					t.[GLAccount],
					t.[MasterCompanyId],
					t.[CreatedBy],
					t.[UpdatedBy],
					t.[CreatedDate],
					t.[UpdatedDate],
					t.[IsActive],
					t.[IsDeleted]
				FROM [DBO].[ItemMasterSettingsAudit] t WITH (NOLOCK) 
				WHERE t.[ItemMasterSettingsId] = @ItemMasterSettingsId ORDER BY t.[ItemMasterSettingsAuditId] DESC
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_ItemMasterSettings_GetHistorById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterSettingsId, '') + ''
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