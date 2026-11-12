/*************************************************************
 ** File:   [USP_DeletePreliminaryInspectionPhoto]
 ** Author: RAJESH GAMI
 ** Description: Removes (soft delete) a photo of the report. Allowed only while the report is in Draft.
 **              Returns one row: Success, Message.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_DeletePreliminaryInspectionPhoto] @PreliminaryInspectionReportPhotoId = 1, @UserName = 'ADMIN User'
**************************************************************/
CREATE PROCEDURE [dbo].[USP_DeletePreliminaryInspectionPhoto]
@PreliminaryInspectionReportPhotoId BIGINT,
@UserName VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @Status VARCHAR(20), @Now DATETIME2(7) = GETUTCDATE();

		SELECT @Status = R.[ReportStatus]
		  FROM [dbo].[PreliminaryInspectionReportPhoto] P WITH(NOLOCK)
		       INNER JOIN [dbo].[PreliminaryInspectionReport] R WITH(NOLOCK) ON R.[PreliminaryInspectionReportId] = P.[PreliminaryInspectionReportId]
		 WHERE P.[PreliminaryInspectionReportPhotoId] = @PreliminaryInspectionReportPhotoId AND P.[IsDeleted] = 0;

		IF (@Status IS NULL)
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'Photo was not found.' AS [Message];
			RETURN;
		END
		IF (@Status <> 'Draft')
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'Photos can be changed only while the report is in Draft.' AS [Message];
			RETURN;
		END

		UPDATE [dbo].[PreliminaryInspectionReportPhoto]
		   SET [IsDeleted] = 1, [UpdatedBy] = @UserName, [UpdatedDate] = @Now
		 WHERE [PreliminaryInspectionReportPhotoId] = @PreliminaryInspectionReportPhotoId;

		SELECT CAST(1 AS BIT) AS [Success], 'Photo deleted successfully.' AS [Message];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_DeletePreliminaryInspectionPhoto'
			, @ProcedureParameters VARCHAR(3000) = '@PreliminaryInspectionReportPhotoId = ''' + CAST(ISNULL(@PreliminaryInspectionReportPhotoId, '') AS VARCHAR(100)) + ''''
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
