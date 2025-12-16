/*************************************************************
 ** File:  [usp_getEmailTemplates_byTemplateType] 
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used to get the Email Templates By the Template Type
 ** Date:  12-Dec-2025
 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description            
 ** --   --------			-------				--------------------------------          
    1    12-Dec-2025		Devendra Shekh		  Created

EXEC [dbo].[usp_getEmailTemplates_byTemplateType] 1
**************************************************************/ 
CREATE   PROCEDURE [dbo].[usp_getEmailTemplates_byTemplateType] (
	@MasterCompanyId INT = NULL
)
AS    
BEGIN    
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON   
	BEGIN TRY
	BEGIN

		SELECT 
			[TemplateId],
			[TemplateName],
			[Description],
			[Subject],
			[EmailBody],
			[MasterCompanyId],
			[CreatedBy],
			[CreatedDate],
			[UpdatedBy],
			[UpdatedDate],
			[IsActive],
			[IsDeleted]
		FROM [RFQFollowUpTemplate] WITH(NOLOCK)
		WHERE [MasterCompanyId] = @MasterCompanyId

	END
	END TRY    
	BEGIN CATCH      
		DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments     VARCHAR(150)    = 'usp_getEmailTemplates_byTemplateType' 
			, @ProcedureParameters VARCHAR(3000)  = ''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException 
			@DatabaseName				= @DatabaseName
			, @AdhocComments			= @AdhocComments
			, @ProcedureParameters		= @ProcedureParameters
			, @ApplicationName			= @ApplicationName
			, @ErrorLogID				= @ErrorLogID OUTPUT ;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
		RETURN(1);
	END CATCH
END