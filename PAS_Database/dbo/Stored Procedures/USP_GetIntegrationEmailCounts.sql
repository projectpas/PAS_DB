/*************************************************************                 
 ** File:   [USP_GetIntegrationEmailCounts]                 
 ** Author:   Moin Bloch
 ** Description: Get Integration Email List  Counts        
 ** Purpose:               
 ** Date:    30/07/2025        
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    30/07/2025   Moin Bloch   	    Created      
    
-- EXEC USP_GetIntegrationEmailCounts 1
**************************************************************/                   
CREATE   PROCEDURE [dbo].[USP_GetIntegrationEmailCounts] 
@MasterCompanyId INT = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
    
	DECLARE	@Inbox INT = 1,@Draft INT = 2,@SentMail INT = 3,@Trash INT = 4        
		 
	SELECT
    SUM(CASE WHEN IE.[EmailSection] = @Inbox THEN 1 ELSE 0 END) AS [Inbox],
    SUM(CASE WHEN IE.[EmailSection] = @Draft THEN 1 ELSE 0 END) AS [Draft],
    SUM(CASE WHEN IE.[EmailSection] = @SentMail THEN 1 ELSE 0 END) AS [SentMail],	
	SUM(CASE WHEN IE.[EmailSection] = @Trash THEN 1 ELSE 0 END) AS [Trash]
  FROM [dbo].[IntegrationEmail] IE WITH(NOLOCK)	      
  WHERE IE.[MasterCompanyId] = @MasterCompanyId
    AND IE.[IsDeleted] = 0
    AND IE.[IsActive] = 1   
	          
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetIntegrationEmailCounts'       
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(1, '') AS varchar(100))             
        + '@Parameter2 = ''' + CAST(ISNULL(@MasterCompanyId  , '') AS varchar(100))   
        , @ApplicationName VARCHAR(100) = 'PAS'      
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------      
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