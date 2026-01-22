/*************************************************************           
 ** File:   [USP_GetEmployeeCommonDetailsList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get EmployeeCommonDetails List
 ** Purpose:         
 ** Date:   16-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    16-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetEmployeeCommonDetailsList]
    @ManagementStructureId BIGINT
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
	     BEGIN TRY

			SELECT
                emp.EmployeeId,
				emp.FirstName,
				emp.LastName,
				emp.MiddleName,
				emp.EmployeeCode,
				emp.WorkPhone,
				emp.Email,
				emp.MasterCompanyId
			FROM [DBO].employee emp WITH(NOLOCK)
			LEFT JOIN [dbo].EmployeeManagementStructure ems WITH(NOLOCK) ON emp.EmployeeId = ems.EmployeeId
			WHERE ISNULL(emp.IsDeleted, 0) = 0 AND ISNULL(emp.IsActive, 0) = 1 AND (emp.ManagementStructureId = @ManagementStructureId OR ems.EmployeeManagementId = @ManagementStructureId);
		END TRY    

    BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetEmployeeCommonDetailsList' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ManagementStructureId, '')
			 
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