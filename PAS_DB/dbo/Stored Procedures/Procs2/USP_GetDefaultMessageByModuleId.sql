/*************************************************************           
 ** File:   [USP_GetDefaultMessageByModuleId]           
 ** Author:   Rajesh Gami
 ** Description: This stored procedure is used to get Default message by module id  
 ** Purpose:         
 ** Date:   11 Nov 2025              
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11 Nov 2025   Rajesh Gami      Created

   EXECUTE [USP_GetDefaultMessageByModuleId] 13,1
**************************************************************/ 
    
CREATE     PROCEDURE [dbo].[USP_GetDefaultMessageByModuleId]
@ModuleId  BIGINT,
@MasterCompanyId BIGINT
AS    
BEGIN    

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON

	BEGIN TRY	
		SELECT TOP 1 
			dm.Description,
			dm.Memo,
			dm.MasterCompanyId,
			dm.ModuleId,
			ISNULL(dm.IsActive,0) IsActive,
			ISNULL(dm.IsDeleted,0) IsDeleted,
			ISNULL(dm.IsDefault,0) IsDefault,
			ISNULL(dm.[Sequence],0) [Sequence]
		FROM DBO.DefaultMessage AS dm WITH(NOLOCK) 
		WHERE dm.MasterCompanyId = @MasterCompanyId
		  AND dm.ModuleId = @ModuleId
		  AND ISNULL(dm.IsActive,0) = 1
		  AND ISNULL(dm.IsDeleted,0) = 0
		  AND ISNULL(dm.IsDefault,0) = 1;	     

	END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetDefaultMessageByModuleId' 
              , @ProcedureParameters VARCHAR(3000)  = '@ModuleId = ' + ISNULL(CAST(@ModuleId AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END