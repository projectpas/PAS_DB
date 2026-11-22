/*************************************************************
 ** File:   [USP_GetSubComponentAuditDetails]
 ** Description: History (SubComponentAudit) of a Sub Component, latest first - same columns as the Sub-Assy history popup.
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    05/11/2026		Kishor Makwana		[PN-18497] Created
**************************************************************/
-- EXEC [dbo].[USP_GetSubComponentAuditDetails] @SubComponentId = 1, @EmployeeId = 1
CREATE   PROCEDURE [dbo].[USP_GetSubComponentAuditDetails]
	@SubComponentId BIGINT,
	@EmployeeId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
		FROM dbo.Employee E WITH (NOLOCK)
			LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
			LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
			LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
		WHERE E.EmployeeId = @EmployeeId;

		SELECT
			A.[SubComponentAuditId],
			A.[SubComponentId],
			IM.[ItemMasterId],
			A.[MappingItemMasterId],
			IM.[Partnumber],
			IMP.[Partnumber] AS [AltPartNo],
			IMP.[PartDescription] AS [AltPartDescription],
			A.[Quantity],
			A.[ConditionId],
			C.[Description] AS [Condition],
			A.[WorkscopeId],
			WS.[WorkScopeCode] AS [WorkScope],
			CASE WHEN A.[IsAutoCreateStockline] = 1 THEN 'yes' ELSE 'no' END AS [IsAutoCreateStockline],
			A.[Memo],
			(CAST(DBO.ConvertUTCtoLocal(A.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) AS [CreatedDate],
			(CAST(DBO.ConvertUTCtoLocal(A.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATETIME)) AS [UpdatedDate],
			UPPER(A.[CreatedBy]) AS [CreatedBy],
			UPPER(A.[UpdatedBy]) AS [UpdatedBy],
			A.[IsActive],
			A.[IsDeleted]
		FROM [dbo].[SubComponentAudit] A WITH (NOLOCK)
		INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = A.[ItemMasterId]
		INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON IMP.[ItemMasterId] = A.[MappingItemMasterId]
		LEFT JOIN [dbo].[Condition] C WITH (NOLOCK) ON C.[ConditionId] = A.[ConditionId]
		LEFT JOIN [dbo].[WorkScope] WS WITH (NOLOCK) ON WS.[WorkScopeId] = A.[WorkscopeId]
		WHERE A.[SubComponentId] = @SubComponentId
		ORDER BY A.[SubComponentAuditId] DESC;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
			, @AdhocComments VARCHAR(150) = 'USP_GetSubComponentAuditDetails'
			, @ProcedureParameters VARCHAR(3000) = '@SubComponentId = ' + CAST(ISNULL(@SubComponentId, 0) AS VARCHAR(20))
			, @ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName
			, @AdhocComments = @AdhocComments
			, @ProcedureParameters = @ProcedureParameters
			, @ApplicationName = @ApplicationName
			, @ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END