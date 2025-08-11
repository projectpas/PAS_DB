/*************************************************************                 
 ** File:   [USP_UpdateIntegrationEmailConfigration]                 
 ** Author:   Moin Bloch
 ** Description: Get Integration Email Configration 
 ** Purpose:               
 ** Date:    11/08/2025      
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    11/08/2025   Moin Bloch   	    Created      
    
-- EXEC USP_GetIntegrationEmailConfigration 1,0
**************************************************************/                   
create   PROCEDURE [dbo].[USP_UpdateIntegrationEmailConfigration] 
@IntegrationEmailID BIGINT = NULL,
@IsRead INT = NULL
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
  
  		UPDATE [dbo].[IntegrationEmail] SET [IsRead] = @IsRead WHERE [IntegrationEmailID] = @IntegrationEmailID
				          
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_UpdateIntegrationEmailConfigration'       
        , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(1, '') AS varchar(100))             
        + '@Parameter2 = ''' + CAST(ISNULL(@IntegrationEmailID  , '') AS varchar(100))   
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