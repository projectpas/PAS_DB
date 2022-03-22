CREATE PROCEDURE [dbo].[USP_GetMSLevelData]
(    
@MasterCompanyId INT=0
)    
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN
					SELECT DISTINCT 
						CAST(msl.Code AS VARCHAR(250)) + ' - ' + msl.[Description] [Label],
						msl.ID [Value],
						msl.TypeID LevelId
					FROM dbo.ManagementStructureLevel msl WITH (NOLOCK)  
					JOIN dbo.ManagementStructureType mst WITH (NOLOCK) ON msl.TypeID = mst.TypeID
					WHERE msl.MasterCompanyId = @MasterCompanyId  AND msl.IsDeleted = 0 AND msl.IsActive = 1
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMSLevelData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId,'') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END