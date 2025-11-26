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

************************************************************************/
CREATE   PROCEDURE [dbo].[GetTBDUserFromEachCompany]
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
	SET NOCOUNT ON;   
	BEGIN TRY
		SELECT MC.MasterCompanyId, MC.TokenUserName, MC.TokenPassword
		FROM DBO.MasterCompany MC WITH (NOLOCK)
		WHERE MC.MasterCompanyId IN (1, 11, 12, 18, 19, 20, 21);
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