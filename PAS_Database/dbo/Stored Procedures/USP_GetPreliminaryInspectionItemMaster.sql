/*************************************************************
 ** File:   [USP_GetPreliminaryInspectionItemMaster]
 ** Author: RAJESH GAMI
 ** Description: Master data of the Preliminary Inspection checklists (QEC / OTHERPARTS / COMPONENTS) of a company.
 ** Date:   10-Nov-2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date          Author          Change Description
 ** --   --------      -------         --------------------------------
    1    10-Nov-2026   RAJESH GAMI     [PN-18515] Created

--   EXEC [dbo].[USP_GetPreliminaryInspectionItemMaster] @MasterCompanyId = 30, @SectionCode = 'QEC', @IncludeInactive = 1
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetPreliminaryInspectionItemMaster]
@MasterCompanyId INT,
@SectionCode VARCHAR(20) = NULL,
@IncludeInactive BIT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		SELECT M.[PreliminaryInspectionItemMasterId], M.[MasterCompanyId], M.[SectionCode], M.[ItemName], M.[SortOrder],
		       M.[OptionLabel1], M.[OptionLabel2], M.[IsActive], M.[CreatedBy], M.[CreatedDate], M.[UpdatedBy], M.[UpdatedDate]
		  FROM [dbo].[PreliminaryInspectionItemMaster] M WITH(NOLOCK)
		 WHERE M.[MasterCompanyId] = @MasterCompanyId AND M.[IsDeleted] = 0
		   AND (@SectionCode IS NULL OR M.[SectionCode] = @SectionCode)
		   AND (ISNULL(@IncludeInactive, 0) = 1 OR M.[IsActive] = 1)
		 ORDER BY CASE M.[SectionCode] WHEN 'QEC' THEN 1 WHEN 'OTHERPARTS' THEN 2 ELSE 3 END, M.[SortOrder], M.[PreliminaryInspectionItemMasterId];
	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetPreliminaryInspectionItemMaster'
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
