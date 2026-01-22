CREATE   PROCEDURE [dbo].[USP_GetItemMasterSettings_ById]
@MasterCompanyId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				
				SELECT 
					ims.[ItemMasterSettingsId],
					ims.[GLAccountId],
					ims.[GLAccount],
					ims.[UnitOfMeasureId],
					ims.[UnitOfMeasure],
					ims.[MasterCompanyId],
					ims.[CreatedBy],
					ims.[CreatedDate],
					ims.[UpdatedBy],
					ims.[UpdatedDate],
					ims.[IsActive],
					ims.[IsDeleted]
				FROM [DBO].[ItemMasterSettings] ims WITH (NOLOCK)				
				WHERE ims.[MasterCompanyId] = @MasterCompanyId
                
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetItemMasterSettings_ById' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''
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