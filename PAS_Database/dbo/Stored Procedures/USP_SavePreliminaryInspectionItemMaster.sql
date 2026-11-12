/*************************************************************
 ** File:   [USP_SavePreliminaryInspectionItemMaster]
 ** Author: RAJESH GAMI
 ** Description: Adds / updates / activates / deactivates / deletes (soft) an item of a Preliminary Inspection checklist (company master data).
 **              Returns one row: PreliminaryInspectionItemMasterId, Success, Message.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_SavePreliminaryInspectionItemMaster] @MasterCompanyId = 30, @SectionCode = 'QEC', @ItemName = 'Starter Generator', @SortOrder = 13, @UserName = 'ADMIN User'
**************************************************************/
CREATE PROCEDURE [dbo].[USP_SavePreliminaryInspectionItemMaster]
@PreliminaryInspectionItemMasterId BIGINT = NULL,
@MasterCompanyId INT,
@SectionCode VARCHAR(20),
@ItemName VARCHAR(200),
@SortOrder INT = 0,
@OptionLabel1 VARCHAR(100) = NULL,
@OptionLabel2 VARCHAR(100) = NULL,
@IsActive BIT = 1,
@IsDeleted BIT = 0,
@UserName VARCHAR(256)
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @Now DATETIME2(7) = GETUTCDATE();

		SET @ItemName = LTRIM(RTRIM(ISNULL(@ItemName, '')));

		IF (@SectionCode NOT IN ('QEC', 'OTHERPARTS', 'COMPONENTS'))
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionItemMasterId], CAST(0 AS BIT) AS [Success], 'Invalid section.' AS [Message];
			RETURN;
		END
		IF (@ItemName = '' AND ISNULL(@IsDeleted, 0) = 0)
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionItemMasterId], CAST(0 AS BIT) AS [Success], 'Item name is required.' AS [Message];
			RETURN;
		END
		IF (ISNULL(@IsDeleted, 0) = 0 AND EXISTS (SELECT 1 FROM [dbo].[PreliminaryInspectionItemMaster] WITH(NOLOCK)
		     WHERE [MasterCompanyId] = @MasterCompanyId AND [SectionCode] = @SectionCode AND [IsDeleted] = 0
		       AND UPPER([ItemName]) = UPPER(@ItemName)
		       AND [PreliminaryInspectionItemMasterId] <> ISNULL(@PreliminaryInspectionItemMasterId, 0)))
		BEGIN
			SELECT CAST(0 AS BIGINT) AS [PreliminaryInspectionItemMasterId], CAST(0 AS BIT) AS [Success], 'This item already exists in the list.' AS [Message];
			RETURN;
		END

		IF (ISNULL(@PreliminaryInspectionItemMasterId, 0) = 0)
		BEGIN
			INSERT INTO [dbo].[PreliminaryInspectionItemMaster]
			       ([MasterCompanyId], [SectionCode], [ItemName], [SortOrder], [OptionLabel1], [OptionLabel2],
			        [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted])
			VALUES (@MasterCompanyId, @SectionCode, @ItemName, ISNULL(@SortOrder, 0), NULLIF(@OptionLabel1, ''), NULLIF(@OptionLabel2, ''),
			        @UserName, @UserName, @Now, @Now, ISNULL(@IsActive, 1), 0);
			SET @PreliminaryInspectionItemMasterId = SCOPE_IDENTITY();
		END
		ELSE
		BEGIN
			UPDATE [dbo].[PreliminaryInspectionItemMaster]
			   SET [SectionCode] = @SectionCode,
			       [ItemName] = CASE WHEN ISNULL(@IsDeleted, 0) = 1 THEN [ItemName] ELSE @ItemName END,
			       [SortOrder] = ISNULL(@SortOrder, [SortOrder]),
			       [OptionLabel1] = NULLIF(@OptionLabel1, ''), [OptionLabel2] = NULLIF(@OptionLabel2, ''),
			       [IsActive] = ISNULL(@IsActive, [IsActive]), [IsDeleted] = ISNULL(@IsDeleted, 0),
			       [UpdatedBy] = @UserName, [UpdatedDate] = @Now
			 WHERE [PreliminaryInspectionItemMasterId] = @PreliminaryInspectionItemMasterId AND [MasterCompanyId] = @MasterCompanyId;
		END

		SELECT @PreliminaryInspectionItemMasterId AS [PreliminaryInspectionItemMasterId], CAST(1 AS BIT) AS [Success], 'Item saved successfully.' AS [Message];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_SavePreliminaryInspectionItemMaster'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100)) + ''', @ItemName = ''' + ISNULL(@ItemName, '') + ''''
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
