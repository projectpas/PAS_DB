/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolOtherReport]
 ** Description: Lease Report (Engine Pool) - "Other" tab. @ViewType : PN = one row per engine (latest lease line), LEASE = one row per lease.
 **              Purpose: Leasing > Reports > Lease Report > Other
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned as NULL (blank in the grid) until its source is agreed.
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created

-- EXEC [dbo].[USP_GetLeaseEnginePoolOtherReport] @MasterCompanyId = 1, @IsActive = 1, @ViewType = 'PN'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseEnginePoolOtherReport]
	@MasterCompanyId INT,
	@IsActive BIT = 1,
	@ItemGroup VARCHAR(256) = NULL,
	@ViewType VARCHAR(10) = 'PN'
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		IF OBJECT_ID('tempdb..#EnginePoolRows') IS NOT NULL DROP TABLE #EnginePoolRows;

		SELECT
			STK.[StockLineId] AS [StockLineId],
			LH.[LeaseNumber] AS [LeaseNumber],
			STK.[PartNumber] AS [EngineSn],
			CAST(NULL AS VARCHAR(200)) AS [BaseModel],
			CAST(NULL AS VARCHAR(200)) AS [EngineType],
			CAST(NULL AS VARCHAR(200)) AS [BringingJobToTs],
			STK.[isActive] AS [IsActive],
			LSL.[LeaseHeaderId]								AS [LeaseHeaderId]
		INTO #EnginePoolRows
		FROM (
				SELECT LS.[StockLineId], LS.[LeaseHeaderId], LS.[StartDate], LS.[EndDate], LS.[UpdatedDate],
					LS.[LeaseStocklineId],
					ROW_NUMBER() OVER (PARTITION BY LS.[StockLineId] ORDER BY ISNULL(LS.[StartDate], '1900-01-01') DESC, LS.[LeaseStocklineId] DESC) AS [RN]
				FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
				WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0
			) LSL
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId] AND ISNULL(LH.[IsDeleted], 0) = 0
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] LCUS WITH (NOLOCK) ON LCUS.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
		WHERE (@ViewType = 'LEASE' OR LSL.[RN] = 1)
			AND STK.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(STK.[isDeleted], 0) = 0
			AND ISNULL(STK.[isActive], 0) = @IsActive
			AND (@ItemGroup IS NULL OR STK.[itemGroup] = @ItemGroup);

		-- PN View   : one row per part (engine) - its latest lease line
		-- Lease View: one row per lease - the part columns show the value, or 'Multiple' when the parts of the lease have different values (same as the Lease List Summary View)
		IF (@ViewType = 'LEASE')
		BEGIN
			SELECT
				CAST(NULL AS BIGINT)							AS [StockLineId],
				MAX(R.[LeaseNumber]) AS [LeaseNumber],
				CASE WHEN COUNT(DISTINCT R.[EngineSn]) > 1 THEN 'Multiple' ELSE MAX(R.[EngineSn]) END AS [EngineSn],
				MAX(R.[BaseModel]) AS [BaseModel],
				MAX(R.[EngineType]) AS [EngineType],
				MAX(R.[BringingJobToTs]) AS [BringingJobToTs],
				CAST(MAX(CAST(R.[IsActive] AS INT)) AS BIT)	AS [IsActive]
			FROM #EnginePoolRows R
			GROUP BY R.[LeaseHeaderId]
			ORDER BY MAX(R.[LeaseNumber]);
		END
		ELSE
		BEGIN
			SELECT
				R.[StockLineId],
				R.[LeaseNumber],
				R.[EngineSn],
				R.[BaseModel],
				R.[EngineType],
				R.[BringingJobToTs],
				R.[IsActive]
			FROM #EnginePoolRows R
			ORDER BY R.[EngineSn], R.[StockLineId];
		END

		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolOtherReport'
			, @ProcedureParameters VARCHAR(3000) = '@MasterCompanyId = ' + ISNULL(CAST(@MasterCompanyId AS VARCHAR(10)), '') + ', @IsActive = ' + ISNULL(CAST(@IsActive AS VARCHAR(1)), '') + ', @ItemGroup = ' + ISNULL(@ItemGroup, '') + ', @ViewType = ' + ISNULL(@ViewType, '')
			, @ApplicationName VARCHAR(100) = 'PAS'
-------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
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