CREATE PROCEDURE [dbo].[USP_GetLoginUserMSDetails]    
(    
@EmployeeId BIGINT
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					SELECT 
						MSL.TypeID LevelId,
						MSL.ID [Value],
						CAST(MSL.Code AS VARCHAR(50)) + ' - ' + MSL.[Description] [Label]	
						FROM dbo.EmployeeManagementStructureMapping EMSM
						JOIN dbo.ManagementStructureLevel MSL WITH (NOLOCK) ON EMSM.ManagementStructureId = MSL.ID
						JOIN dbo.ManagementStructureType MST WITH (NOLOCK) ON MSL.TypeID = MST.TypeID
						WHERE EMSM.EmployeeId = @EmployeeId
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetLoginUserMSDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') + ''
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