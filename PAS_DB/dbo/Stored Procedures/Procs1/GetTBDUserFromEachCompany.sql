/*************************************************************             
 ** File:   [GetTBDUserFromEachCompany]
 ** Author:  VISHAL SUTHAR
 ** Description: This stored procedure is used to get TBD user from each company
 ** Purpose:
 ** Date:  11/25/2025
            
 ** PARAMETERS:
           
 ** RETURN VALUE:
 ************************************************************************
 ** Change History             
 ************************************************************************
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------
    1    11/25/2025		VISHAL SUTHAR	Created
	2    06/19/2026		Moin Bloch    	Added IsActive,IsDeleted Flags
************************************************************************/
CREATE   PROCEDURE [dbo].[GetTBDUserFromEachCompany]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		SELECT MC.MasterCompanyId, MC.TokenUserName, MC.TokenPassword
		FROM [dbo].[MasterCompany] MC WITH (NOLOCK)
		WHERE MC.MasterCompanyId NOT IN (3, 4, 5, 6, 8, 9, 10, 13, 14, 15, 16, 17) 
		  AND ISNULL(MC.IsActive,0) = 1 
		  AND ISNULL(MC.IsDeleted,0) = 0 
		  AND ISNULL(MC.TokenUserName,'') <> '' 
		  AND ISNULL(MC.TokenPassword,'') <> ''
	END TRY
	BEGIN CATCH
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'GetTBDUserFromEachCompany'     
        , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '
        , @ApplicationName VARCHAR(100) = 'PAS'    
-----------------------------------PLEASE DO NOT EDIT BELOW---------------------------------------------------------------------
        exec spLogException     
        @DatabaseName           = @DatabaseName    
        , @AdhocComments          = @AdhocComments    
        , @ProcedureParameters = @ProcedureParameters    
        , @ApplicationName        =  @ApplicationName    
        , @ErrorLogID                    = @ErrorLogID OUTPUT ;    
        RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)    
        RETURN(1); 
	END CATCH
END