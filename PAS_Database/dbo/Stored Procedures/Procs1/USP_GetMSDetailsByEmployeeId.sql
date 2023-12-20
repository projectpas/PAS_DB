

/*************************************************************           
 ** File:   [USP_GetMSDetailsByEmployeeId]           
 ** Author:   Hemant Saliya
 ** Description: This SP is Used to Retrive Managment Structure Level Details By Master Company and EmployeeId
 ** Purpose:         
 ** Date:    02/22/2022        
          
 ** PARAMETERS:           
 @MasterCompanyId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2022   Subhash Saliya Created
     
 EXECUTE USP_GetMSDetailsByEmployeeId 2

**************************************************************/ 
    
create PROCEDURE [dbo].[USP_GetMSDetailsByEmployeeId]    
(    
@MasterCompanyId INT,
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
						EMPSM.ManagementStructureId as ManagementStructureId,
						EMPSM.EmployeeId EmployeeId
					
					FROM dbo.EmployeeManagementStructure EMPSM WITH (NOLOCK)  
					WHERE EMPSM.MasterCompanyId = @MasterCompanyId AND EMPSM.EmployeeId = @EmployeeId AND EMPSM.IsActive = 1 AND EMPSM.IsDeleted = 0
				END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetMSDetailsByEmployeeId' 
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