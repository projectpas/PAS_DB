

/*************************************************************           
 ** File:   [USP_GetMSDetailsByRoleId]           
 ** Author:   Moin Bloch
 ** Description: This SP is Used to Retrive Managment Structure Level Details By Master Company and RoleId
 ** Purpose:         
 ** Date:    28/02/2022        
          
 ** PARAMETERS:           
 @MasterCompanyId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    28/02/2022   Moin Bloch     Created
     
 EXECUTE USP_GetMSDetailsByRoleId 2,2,15

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_GetMSDetailsByRoleId]    
(    
@MasterCompanyId INT,
@RoleId INT,
@EmployeeId INT
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  

					SELECT DISTINCT 
						EMPSM.EntityStructureId,
						EMPSM.RoleId 					
					FROM dbo.RoleManagementStructure EMPSM WITH (NOLOCK)  LEFT JOIN EmployeeUserRole EUR  WITH (NOLOCK) ON EMPSM.RoleId = EUR.RoleId 
					WHERE EMPSM.MasterCompanyId = @MasterCompanyId AND EMPSM.RoleId = @RoleId 
					--AND EmployeeId = @EmployeeId 
					AND EMPSM.IsActive = 1 AND EMPSM.IsDeleted = 0
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMSDetailsByRoleId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@MasterCompanyId, '') + ''
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