/*************************************************************
 ** File:   [USP_GetLeaseAgreementTemplate]
 ** Description: Returns the Lease Agreement print template (HTML with ##TAGS##) of the company:
 **              dbo.EmailTemplate of the EmailTemplateType 'LeaseAgreement'. The type is found by its
 **              NAME (not by a hard coded id), so it works with the id the type got on every database.
 **              Returns no row when the template is not configured.
 **
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date           Author                  Change Description
 ** --   --------       -------                 --------------------------------
    1    02/11/2026     Rajesh Gami             [PN-18468] Created - Lease Agreement PDF template

exec USP_GetLeaseAgreementTemplate @MasterCompanyId=1
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseAgreementTemplate]
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY

		SELECT TOP 1
			T.[EmailTemplateId],
			T.[TemplateName],
			T.[TemplateDescription],
			T.[RevNo],
			T.[RevDate]
		FROM [dbo].[EmailTemplate] T WITH (NOLOCK)
		INNER JOIN [dbo].[EmailTemplateType] TT WITH (NOLOCK) ON TT.[EmailTemplateTypeId] = T.[EmailTemplateTypeId]
		WHERE TT.[EmailTemplateType] = 'LeaseAgreement'
		  AND T.[MasterCompanyId] = @MasterCompanyId
		  AND T.[IsActive] = 1
		  AND T.[IsDeleted] = 0
		ORDER BY T.[EmailTemplateId] DESC;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT,
			@DatabaseName VARCHAR(100) = DB_NAME(),
			@AdhocComments VARCHAR(150) = '[USP_GetLeaseAgreementTemplate]',
			@ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName,
							@AdhocComments = @AdhocComments,
							@ProcedureParameters = @ProcedureParameters,
							@ApplicationName = @ApplicationName,
							@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END
