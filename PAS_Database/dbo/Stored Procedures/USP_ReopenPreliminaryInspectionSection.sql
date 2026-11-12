/*************************************************************
 ** File:   [USP_ReopenPreliminaryInspectionSection]
 ** Author: RAJESH GAMI
 ** Description: Reopens a signed section (clears its sign-off); a Completed report goes back to Draft.
 **              Returns one row: Success, Message, ReportStatus.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_ReopenPreliminaryInspectionSection] @PreliminaryInspectionReportId = 1, @SectionCode = 'SHIPPING', @UserName = 'ADMIN User'
**************************************************************/
CREATE PROCEDURE [dbo].[USP_ReopenPreliminaryInspectionSection]
@PreliminaryInspectionReportId BIGINT,
@SectionCode VARCHAR(20),
@UserName VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @Status VARCHAR(20), @Now DATETIME2(7) = GETUTCDATE();

		SELECT @Status = [ReportStatus]
		  FROM [dbo].[PreliminaryInspectionReport] WITH(NOLOCK)
		 WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [IsDeleted] = 0;

		IF (@Status IS NULL)
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'Report was not found.' AS [Message], CAST(NULL AS VARCHAR(20)) AS [ReportStatus];
			RETURN;
		END
		IF NOT EXISTS (SELECT 1 FROM [dbo].[PreliminaryInspectionReportSignOff] WITH(NOLOCK)
		                WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [SectionCode] = @SectionCode AND [IsSigned] = 1)
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'The section is not signed off.' AS [Message], @Status AS [ReportStatus];
			RETURN;
		END

		BEGIN TRANSACTION;

		UPDATE [dbo].[PreliminaryInspectionReportSignOff]
		   SET [IsSigned] = 0, [SignedBy] = NULL, [SignedByEmployeeId] = NULL, [SignedInitials] = NULL, [SignedDate] = NULL,
		       [ReopenedBy] = @UserName, [ReopenedDate] = @Now, [UpdatedBy] = @UserName, [UpdatedDate] = @Now
		 WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [SectionCode] = @SectionCode;

		IF (@Status = 'Completed')
		BEGIN
			UPDATE [dbo].[PreliminaryInspectionReport]
			   SET [ReportStatus] = 'Draft', [CompletedBy] = NULL, [CompletedDate] = NULL, [UpdatedBy] = @UserName, [UpdatedDate] = @Now
			 WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId;
			SET @Status = 'Draft';
		END

		COMMIT TRANSACTION;

		SELECT CAST(1 AS BIT) AS [Success], 'Section reopened successfully.' AS [Message], @Status AS [ReportStatus];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_ReopenPreliminaryInspectionSection'
			, @ProcedureParameters VARCHAR(3000) = '@PreliminaryInspectionReportId = ''' + CAST(ISNULL(@PreliminaryInspectionReportId, '') AS VARCHAR(100)) + ''', @SectionCode = ''' + ISNULL(@SectionCode, '') + ''''
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
