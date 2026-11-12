/*************************************************************
 ** File:   [USP_GetPreliminaryInspectionTemplate]
 ** Author: RAJESH GAMI
 ** Description: Returns the Preliminary Inspection Report print template (HTML with ##TAGS##) of the company:
 **              dbo.EmailTemplate of the EmailTemplateType 'PreliminaryInspectionReport' (found by NAME, not by id).
 **              Returns no row when the template is not configured.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_GetPreliminaryInspectionTemplate] @MasterCompanyId = 1
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetPreliminaryInspectionTemplate]
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT TOP 1
			T.[EmailTemplateId],
			T.[TemplateName],
			T.[TemplateDescription],
			T.[RevNo],
			T.[RevDate]
		  FROM [dbo].[EmailTemplate] T WITH (NOLOCK)
		       INNER JOIN [dbo].[EmailTemplateType] TT WITH (NOLOCK) ON TT.[EmailTemplateTypeId] = T.[EmailTemplateTypeId]
		 WHERE TT.[EmailTemplateType] = 'PreliminaryInspectionReport'
		   AND T.[MasterCompanyId] = @MasterCompanyId
		   AND T.[IsActive] = 1 AND T.[IsDeleted] = 0
		 ORDER BY T.[EmailTemplateId] DESC;
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetPreliminaryInspectionTemplate'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + ''''
			, @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
			EXEC spLogException
				@DatabaseName = @DatabaseName
				, @AdhocComments = @AdhocComments
				, @ProcedureParameters = @ProcedureParameters
				, @ApplicationName = @ApplicationName
				, @ErrorLogID = @ErrorLogID OUTPUT;
			RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
			RETURN(1);
	END CATCH
END
