/*************************************************************           
 ** File:   [USP_GetEmpoyeeManagementStructureList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get Employee ManagementStructure List
 ** Purpose:         
 ** Date:   18-06-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    18-06-2025    Sahdev Saliya       Created  

**************************************************************/ 
CREATE   PROCEDURE [dbo].[USP_GetEmpoyeeManagementStructureList]
    @EmployeeId  BIGINT       
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
		BEGIN TRY

			SELECT 
			        ems.EmployeeManagementId,
					ems.EmployeeId,
					ems.ManagementStructureId,
					ems.MasterCompanyId,
					ems.CreatedBy,
					ems.CreatedDate,
					ems.UpdatedBy,
					ems.UpdatedDate,
					ems.IsActive,
					ems.IsDeleted
			FROM [DBO].EmployeeManagementStructure ems WITH(NOLOCK)
			WHERE ems.EmployeeId = @EmployeeId AND ISNULL(ems.IsActive, 0) = 1;
	    END TRY

   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetEmpoyeeManagementStructureList' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@EmployeeId, '') 

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