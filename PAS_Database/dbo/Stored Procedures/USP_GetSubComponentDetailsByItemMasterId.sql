/*************************************************************
 ** File:   [USP_GetSubComponentDetailsByItemMasterId]
 ** Description: Sub Components list of a PN (Item Master > Sub Assembly > Sub Components) - paging, sorting and column filters. Same shape as USP_AssemplyDetailsByAssemplyId (Work Order Sub-Assy); only stock items (IsNonStock = 0).
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    05/11/2026		Kishor Makwana		[PN-18497] Created
**************************************************************/
-- EXEC [dbo].[USP_GetSubComponentDetailsByItemMasterId] @PageNumber = 1, @PageSize = 10, @MasterCompanyId = 1, @ItemMasterId = 1, @EmployeeId = 1
CREATE   PROCEDURE [dbo].[USP_GetSubComponentDetailsByItemMasterId]
	@PageNumber INT = 1,
	@PageSize INT = 10,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT = NULL,
	@GlobalFilter VARCHAR(50) = NULL,
	@StatusId INT = NULL,
	@Partnumber VARCHAR(50) = NULL,
	@PartDescription VARCHAR(50) = NULL,
	@Quantity VARCHAR(50) = NULL,
	@Condition VARCHAR(50) = NULL,
	@WorkScope VARCHAR(50) = NULL,
	@IsAutoCreateStockline VARCHAR(50) = NULL,
	@Memo VARCHAR(500) = NULL,
	@MasterCompanyId INT,
	@ItemMasterId BIGINT,
	@MappingItemMasterId BIGINT = NULL,
	@CreatedBy VARCHAR(50) = NULL,
	@CreatedDate DATETIME = NULL,
	@UpdatedBy VARCHAR(50) = NULL,
	@UpdatedDate DATETIME = NULL,
	@IsDeleted BIT = NULL,
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
		DECLARE @RecordFrom INT, @Count INT, @IsActive BIT;

		IF (ISNULL(@PageNumber, 0) < 1) SET @PageNumber = 1;
		IF (ISNULL(@PageSize, 0) < 1) SET @PageSize = 10;
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		SET @IsDeleted = ISNULL(@IsDeleted, 0);
		SET @GlobalFilter = ISNULL(@GlobalFilter, '');
		SET @SortColumn = UPPER(ISNULL(@SortColumn, 'CreatedDate'));
		SET @IsActive = CASE WHEN @StatusId = 0 THEN 0 WHEN @StatusId = 1 THEN 1 ELSE NULL END;

		;WITH Result AS (
			SELECT
				LSC.[SubComponentId],
				IM.[ItemMasterId],
				LSC.[MappingItemMasterId],
				IM.[Partnumber],
				IMP.[Partnumber] AS [AltPartNo],
				IMP.[PartDescription],
				LSC.[Quantity],
				LSC.[ConditionId],
				C.[Description] AS [Condition],
				LSC.[WorkscopeId],
				WS.[WorkScopeCode] AS [WorkScope],
				CASE WHEN LSC.[IsAutoCreateStockline] = 1 THEN 'yes' ELSE 'no' END AS [IsAutoCreateStockline],
				LSC.[Memo],
				(CAST(DBO.ConvertUTCtoLocal(LSC.[CreatedDate], @CurrntEmpTimeZoneDesc) AS DATE)) AS [CreatedDate],
				(CAST(DBO.ConvertUTCtoLocal(LSC.[UpdatedDate], @CurrntEmpTimeZoneDesc) AS DATE)) AS [UpdatedDate],
				UPPER(LSC.[CreatedBy]) AS [CreatedBy],
				UPPER(LSC.[UpdatedBy]) AS [UpdatedBy],
				LSC.[IsActive],
				LSC.[IsDeleted]
			FROM [dbo].[SubComponent] LSC WITH (NOLOCK)
			INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON IM.[ItemMasterId] = LSC.[ItemMasterId]
			INNER JOIN [dbo].[ItemMaster] IMP WITH (NOLOCK) ON IMP.[ItemMasterId] = LSC.[MappingItemMasterId]
			LEFT JOIN [dbo].[Condition] C WITH (NOLOCK) ON C.[ConditionId] = LSC.[ConditionId]
			LEFT JOIN [dbo].[WorkScope] WS WITH (NOLOCK) ON WS.[WorkScopeId] = LSC.[WorkscopeId]
			WHERE LSC.[IsDeleted] = @IsDeleted AND (@IsActive IS NULL OR LSC.[IsActive] = @IsActive)
				AND LSC.[MasterCompanyId] = @MasterCompanyId AND LSC.[ItemMasterId] = @ItemMasterId
				AND (ISNULL(@MappingItemMasterId, 0) = 0 OR LSC.[MappingItemMasterId] = @MappingItemMasterId)
				AND ISNULL(IM.[IsNonStock], 0) = 0 AND ISNULL(IMP.[IsNonStock], 0) = 0
		)
		SELECT * INTO #TempResult FROM Result
		WHERE ((@GlobalFilter <> '' AND (
				([AltPartNo] LIKE '%' + @GlobalFilter + '%') OR
				([PartDescription] LIKE '%' + @GlobalFilter + '%') OR
				(CAST([Quantity] AS VARCHAR(20)) LIKE '%' + @GlobalFilter + '%') OR
				([Condition] LIKE '%' + @GlobalFilter + '%') OR
				([WorkScope] LIKE '%' + @GlobalFilter + '%') OR
				([IsAutoCreateStockline] LIKE '%' + @GlobalFilter + '%') OR
				([Memo] LIKE '%' + @GlobalFilter + '%') OR
				([CreatedBy] LIKE '%' + @GlobalFilter + '%') OR
				([UpdatedBy] LIKE '%' + @GlobalFilter + '%')))
			OR (@GlobalFilter = '' AND
				(ISNULL(@Partnumber, '') = '' OR [AltPartNo] LIKE '%' + @Partnumber + '%') AND
				(ISNULL(@PartDescription, '') = '' OR [PartDescription] LIKE '%' + @PartDescription + '%') AND
				(ISNULL(@Quantity, '') = '' OR CAST([Quantity] AS VARCHAR(20)) LIKE '%' + @Quantity + '%') AND
				(ISNULL(@Condition, '') = '' OR [Condition] LIKE '%' + @Condition + '%') AND
				(ISNULL(@WorkScope, '') = '' OR [WorkScope] LIKE '%' + @WorkScope + '%') AND
				(ISNULL(@IsAutoCreateStockline, '') = '' OR [IsAutoCreateStockline] LIKE '%' + @IsAutoCreateStockline + '%') AND
				(ISNULL(@Memo, '') = '' OR [Memo] LIKE '%' + @Memo + '%') AND
				(ISNULL(@CreatedBy, '') = '' OR [CreatedBy] LIKE '%' + @CreatedBy + '%') AND
				(ISNULL(@UpdatedBy, '') = '' OR [UpdatedBy] LIKE '%' + @UpdatedBy + '%') AND
				(@CreatedDate IS NULL OR [CreatedDate] = CAST(@CreatedDate AS DATE)) AND
				(@UpdatedDate IS NULL OR [UpdatedDate] = CAST(@UpdatedDate AS DATE))));

		SELECT @Count = COUNT(*) FROM #TempResult;

		SELECT *, @Count AS [NumberOfItems] FROM #TempResult
		ORDER BY
			CASE WHEN (@SortOrder = 1  AND @SortColumn IN ('PARTNUMBER', 'ALTPARTNO')) THEN [AltPartNo] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn IN ('PARTNUMBER', 'ALTPARTNO')) THEN [AltPartNo] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'PARTDESCRIPTION') THEN [PartDescription] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'PARTDESCRIPTION') THEN [PartDescription] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'QUANTITY') THEN [Quantity] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'QUANTITY') THEN [Quantity] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CONDITION') THEN [Condition] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CONDITION') THEN [Condition] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'WORKSCOPE') THEN [WorkScope] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'WORKSCOPE') THEN [WorkScope] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'ISAUTOCREATESTOCKLINE') THEN [IsAutoCreateStockline] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ISAUTOCREATESTOCKLINE') THEN [IsAutoCreateStockline] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'MEMO') THEN [Memo] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'MEMO') THEN [Memo] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CREATEDBY') THEN [CreatedBy] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDBY') THEN [CreatedBy] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CREATEDDATE') THEN [CreatedDate] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CREATEDDATE') THEN [CreatedDate] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'UPDATEDBY') THEN [UpdatedBy] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDBY') THEN [UpdatedBy] END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'UPDATEDDATE') THEN [UpdatedDate] END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'UPDATEDDATE') THEN [UpdatedDate] END DESC,
			[SubComponentId] DESC
		OFFSET @RecordFrom ROWS
		FETCH NEXT @PageSize ROWS ONLY;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()
			, @AdhocComments VARCHAR(150) = 'USP_GetSubComponentDetailsByItemMasterId'
			, @ProcedureParameters VARCHAR(3000) = '@ItemMasterId = ' + CAST(ISNULL(@ItemMasterId, 0) AS VARCHAR(20)) + ', @MasterCompanyId = ' + CAST(ISNULL(@MasterCompanyId, 0) AS VARCHAR(20))
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