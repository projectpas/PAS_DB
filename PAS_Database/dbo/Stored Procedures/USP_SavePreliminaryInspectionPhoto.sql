/*************************************************************
 ** File:   [USP_SavePreliminaryInspectionPhoto]
 ** Author: RAJESH GAMI
 ** Description: Stores the file name / path of an uploaded photo (section SHIPPING or ENGINE). Allowed only while the report is in Draft.
 **              Returns one row: PreliminaryInspectionReportPhotoId, Success, Message.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_SavePreliminaryInspectionPhoto] @PreliminaryInspectionReportId = 1, @SectionCode = 'ENGINE', @FileName = 'engine.jpg', @FilePath = '/30/PreliminaryInspection/101601/engine.jpg', @UserName = 'ADMIN User'
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SavePreliminaryInspectionPhoto]
@PreliminaryInspectionReportId BIGINT,
@SectionCode VARCHAR(20),
@FileName VARCHAR(500),
@FilePath VARCHAR(1000),
@FileType VARCHAR(200) = NULL,
@FileSize DECIMAL(18, 2) = NULL,
@UserName VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @Status VARCHAR(20), @MasterCompanyId INT, @Now DATETIME2(7) = GETUTCDATE(), @Id BIGINT;

		SELECT @Status = [ReportStatus], @MasterCompanyId = [MasterCompanyId]
		  FROM [dbo].[PreliminaryInspectionReport] WITH(NOLOCK)
		 WHERE [PreliminaryInspectionReportId] = @PreliminaryInspectionReportId AND [IsDeleted] = 0;

		IF (@Status IS NULL)
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionReportPhotoId], CAST(0 AS BIT) AS [Success], 'Save the report before uploading photos.' AS [Message];
			RETURN;
		END
		IF (@Status <> 'Draft')
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionReportPhotoId], CAST(0 AS BIT) AS [Success], 'Photos can be changed only while the report is in Draft.' AS [Message];
			RETURN;
		END
		IF (@SectionCode NOT IN ('SHIPPING', 'ENGINE'))
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionReportPhotoId], CAST(0 AS BIT) AS [Success], 'Invalid photo section.' AS [Message];
			RETURN;
		END

		INSERT INTO [dbo].[PreliminaryInspectionReportPhoto]
		       ([PreliminaryInspectionReportId], [MasterCompanyId], [SectionCode], [FileName], [FilePath], [FileType], [FileSize],
		        [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
		VALUES (@PreliminaryInspectionReportId, @MasterCompanyId, @SectionCode, @FileName, @FilePath, @FileType, @FileSize,
		        @UserName, @UserName, @Now, @Now, 1, 0);

		SET @Id = SCOPE_IDENTITY();

		SELECT @Id AS [PreliminaryInspectionReportPhotoId], CAST(1 AS BIT) AS [Success], 'Photo uploaded successfully.' AS [Message];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SavePreliminaryInspectionPhoto'
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
