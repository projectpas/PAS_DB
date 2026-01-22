/*************************************************************           
 ** File:   [USP_GetEmployeeUserRoleList]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get Employee UserRole List
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
CREATE   PROCEDURE [dbo].[USP_GetEmployeeUserRoleList]
    @EmployeeId  BIGINT       
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON;
		BEGIN TRY

			SELECT 
			        eur.EmployeeUserRoleId,
					eur.EmployeeId,
					eur.RoleId,
					eur.IsActive,
					eur.IsDeleted,
					eur.CreatedBy,
					eur.CreatedDate,
					eur.UpdatedBy,
					eur.UpdatedDate
			FROM [DBO].EmployeeUserRole eur WITH(NOLOCK)
			WHERE eur.EmployeeId = @EmployeeId AND ISNULL(eur.IsActive, 0) = 1;
	    END TRY

   BEGIN CATCH      
				IF @@trancount > 0
					PRINT 'ROLLBACK'
					DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'USP_GetEmployeeUserRoleList' 
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