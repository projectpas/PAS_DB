/*************************************************************
 ** File:   [USP_SignOffPreliminaryInspectionSection]
 ** Author: RAJESH GAMI
 ** Description: Technician sign-off of one section (SHIPPING / ENGINE / PARTS = QEC + other parts + components + notes / REVIEW): stores the name / initials of the
 **              logged in user and the date-time. The report becomes Completed when all 4 sections are signed.
 **              Returns one row: Success, Message, ReportStatus.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_SignOffPreliminaryInspectionSection] @PreliminaryInspectionReportId = 1, @SectionCode = 'SHIPPING', @UserName = 'ADMIN User', @EmployeeId = 2
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SignOffPreliminaryInspectionSection]
@PreliminaryInspectionReportId BIGINT,
@SectionCode VARCHAR(20),
@UserName VARCHAR(256),
@EmployeeId BIGINT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @Status VARCHAR(20), @MasterCompanyId INT, @Now DATETIME2(7) = GETUTCDATE(), @FullName VARCHAR(256), @Initials VARCHAR(20);

		SELECT @Status = [ReportStatus], @MasterCompanyId = [MasterCompanyId]
		  FROM [dbo].[PreliminaryInspectionReport] WITH(NOLOCK)
		 WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [IsDeleted] = 0;

		IF (@Status IS NULL)
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'Save the report before the sign-off.' AS [Message], CAST(NULL AS VARCHAR(20)) AS [ReportStatus];
			RETURN;
		END
		IF (@SectionCode NOT IN ('SHIPPING', 'ENGINE', 'PARTS', 'REVIEW'))
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'Invalid section.' AS [Message], @Status AS [ReportStatus];
			RETURN;
		END
		IF EXISTS (SELECT 1 FROM [dbo].[PreliminaryInspectionReportSignOff] WITH(NOLOCK)
		            WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [SectionCode] = @SectionCode AND [IsSigned] = 1)
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'The section is already signed off.' AS [Message], @Status AS [ReportStatus];
			RETURN;
		END

		IF (@SectionCode = 'REVIEW' AND (SELECT COUNT(1) FROM [dbo].[PreliminaryInspectionReportSignOff] WITH(NOLOCK)
		     WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [SectionCode] IN ('SHIPPING', 'ENGINE', 'PARTS') AND [IsSigned] = 1) < 3)
		BEGIN
			SELECT CAST(0 AS BIT) AS [Success], 'Sign off the other sections before the review.' AS [Message], @Status AS [ReportStatus];
			RETURN;
		END

		SELECT @FullName = LTRIM(RTRIM(ISNULL(E.[FirstName], '') + ' ' + ISNULL(E.[LastName], ''))),
		       @Initials = UPPER(LEFT(LTRIM(ISNULL(E.[FirstName], '')), 1) + LEFT(LTRIM(ISNULL(E.[LastName], '')), 1))
		  FROM [dbo].[Employee] E WITH(NOLOCK) WHERE E.[EmployeeId] = @EmployeeId;

		IF (ISNULL(@FullName, '') = '') SET @FullName = @UserName;
		IF (ISNULL(@Initials, '') = '')
			SET @Initials = UPPER(LEFT(LTRIM(ISNULL(@UserName, '')), 2));

		BEGIN TRANSACTION;

		IF NOT EXISTS (SELECT 1 FROM [dbo].[PreliminaryInspectionReportSignOff] WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [SectionCode] = @SectionCode)
			INSERT INTO [dbo].[PreliminaryInspectionReportSignOff] ([PreliminaryInspectionReportId], [MasterCompanyId], [SectionCode], [IsSigned], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES (@PreliminaryInspectionReportId, @MasterCompanyId, @SectionCode, 0, @UserName, @UserName, @Now, @Now, 1, 0);

		UPDATE [dbo].[PreliminaryInspectionReportSignOff]
		   SET [IsSigned] = 1, [SignedBy] = @FullName, [SignedByEmployeeId] = @EmployeeId, [SignedInitials] = @Initials,
		       [SignedDate] = @Now, [UpdatedBy] = @UserName, [UpdatedDate] = @Now
		 WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [SectionCode] = @SectionCode;

		IF ((SELECT COUNT(1) FROM [dbo].[PreliminaryInspectionReportSignOff] WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [IsSigned] = 1) >= 4)
		BEGIN
			UPDATE [dbo].[PreliminaryInspectionReport]
			   SET [ReportStatus] = 'Completed', [CompletedBy] = @FullName, [CompletedDate] = @Now, [UpdatedBy] = @UserName, [UpdatedDate] = @Now
			 WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId;
			SET @Status = 'Completed';
		END

		COMMIT TRANSACTION;

		SELECT CAST(1 AS BIT) AS [Success], 'Section signed off successfully.' AS [Message], @Status AS [ReportStatus];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SignOffPreliminaryInspectionSection'
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
