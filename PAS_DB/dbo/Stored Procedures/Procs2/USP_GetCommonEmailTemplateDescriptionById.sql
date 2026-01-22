/*****************************************************************************************           
 ** File:   [USP_GetCommonEmailTemplateDescriptionById]           
 ** Author:   Moin Bloch 
 ** Description: This stored procedure is used to Get Common Email Template Description 
 ** Purpose:         
 ** Date:   21/05/2025      
 ** RETURN VALUE:           
 ******************************************************************************************           
 ** Change History           
 ******************************************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    21/05/2025   Moin Bloch    Created
     
--   EXEC [dbo].[USP_GetCommonEmailTemplateDescriptionById] 14,1
********************************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetCommonEmailTemplateDescriptionById]
@EmailTemplateTypeId BIGINT = NULL,
@MasterCompanyId INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		  SELECT TOP 1 [EmailTemplateId]
			    ,[TemplateName]
			    ,[TemplateDescription]
			    ,[MasterCompanyId]
			    ,[CreatedBy]
			    ,[UpdatedBy]
			    ,[CreatedDate]
			    ,[UpdatedDate]
			    ,[IsActive]
			    ,[IsDeleted]
			    ,[EmailBody]
			    ,[EmailTemplateTypeId]
			    ,[SubjectName]
			    ,[RevNo]
			    ,[RevDate]
			    ,[ModuleName]
			    ,[SubModuleName]
			    ,[IsTemplateType]
			FROM [dbo].[EmailTemplate]
		   WHERE [EmailTemplateTypeId] = @EmailTemplateTypeId 
		     AND [MasterCompanyId] = @MasterCompanyId	
			 AND [IsActive] = 1 
			 AND [IsDeleted] = 0
	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
              DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetCommonEmailTemplateDescriptionById' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@EmailTemplateTypeId, '') AS VARCHAR(100))
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