/*************************************************************                 
 ** File:   [[USP_GetIntegrationEmailAttachments]]                 
 ** Author:   Moin Bloch
 ** Description: Get Integration Email List  Attachments        
 ** Purpose:               
 ** Date:    01/08/2025        
 **************************************************************                 
  ** Change History                 
 **************************************************************                 
 ** PR   Date         Author  Change	Description                  
 ** --   --------     -------  ------	--------------------------                
    1    01/08/2025   Moin Bloch   	    Created      
    
-- EXEC USP_GetIntegrationEmailAttachments 25
**************************************************************/                   
CREATE   PROCEDURE [dbo].[USP_GetIntegrationEmailAttachments] 
@IntegrationEmailID BIGINT
AS      
BEGIN      
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED      
 SET NOCOUNT ON;      
 BEGIN TRY      
    
	SELECT IA.[IntegrationEmailAttachmentID]
		  ,IA.[IntegrationEmailID]
		  ,IA.[AttachmentName]
		  ,IA.[AttachmentPath]
		  ,IE.[FromEmail]
	  FROM [dbo].[IntegrationEmailAttachment] IA WITH(NOLOCK)
	  LEFT JOIN [dbo].[IntegrationEmail] IE WITH(NOLOCK) ON IA.[IntegrationEmailID] = IE.[IntegrationEmailID]
	  WHERE IA.[IntegrationEmailID] = @IntegrationEmailID
	          
 END TRY          
 BEGIN CATCH      
  DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()       
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------      
        , @AdhocComments     VARCHAR(150)    = 'USP_GetIntegrationEmailCounts'       
        ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(1, '') AS VARCHAR(100))             
        + '@Parameter2 = ''' + CAST(ISNULL(@IntegrationEmailID  , '') AS VARCHAR(100))   
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