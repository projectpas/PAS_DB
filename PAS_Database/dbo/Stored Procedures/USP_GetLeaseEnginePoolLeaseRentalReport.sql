/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolLeaseRentalReport]
 ** Description: Lease Report (Engine Pool) - "Lease/Rental" tab. One row per engine (stockline).
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned as NULL (blank in the grid) until its source is agreed.
 ** Purpose: Leasing > Reports > Lease Report > Lease/Rental 
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created
    
-- EXEC [dbo].[USP_GetLeaseEnginePoolLeaseRentalReport] @MasterCompanyId = 1, @IsActive = 1, @ViewType = 'PN'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseEnginePoolLeaseRentalReport]
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
			STK.[StockLineId]								AS [StockLineId],
			LH.[LeaseNumber]								AS [LeaseNumber],
			STK.[PartNumber]								AS [EngineSn],
			CAST(NULL AS VARCHAR(200))						AS [BaseModel],
			CAST(NULL AS VARCHAR(200))						AS [EngineType],
			LOC.[Name]										AS [Location],
			CAST(NULL AS VARCHAR(200))						AS [Disposition],
			LCUS.[Name]										AS [Lessee],
			LT.[LeaseType]									AS [LeaseType],
			LSL.[StartDate]									AS [RentalDate],
			LSL.[EndDate]									AS [RentalExpiration],
			CAST(NULL AS DATETIME2(7))						AS [CoiExpiration],
			LSL.[UpdatedDate]								AS [DateUpdated],
			CAST(NULL AS DECIMAL(18, 2))					AS [RentalIncome],
			CAST(NULL AS DECIMAL(18, 2))					AS [MtxExpAc6310],
			CAST(NULL AS DECIMAL(18, 2))					AS [Roi],
			STK.[isActive]									AS [IsActive],
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
			LEFT JOIN [dbo].[LeaseType] LT WITH (NOLOCK) ON LT.[LeaseTypeId] = LH.[LeaseTypeId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
		WHERE (@ViewType = 'LEASE' OR LSL.[RN] = 1)
			AND STK.[MasterCompanyId] = @MasterCompanyId
			AND ISNULL(STK.[isDeleted], 0) = 0
			AND ISNULL(STK.[isActive], 0) = @IsActive
			AND (@ItemGroup IS NULL OR STK.[itemGroup] = @ItemGroup);

		-- PN View   : one row per part (engine) - its latest lease line
		-- Lease View: one row per lease - the amounts are the sum of all the parts of the lease, the part columns show the value, or 'Multiple' when the parts of the lease have different values (same as the Lease List Summary View)
		IF (@ViewType = 'LEASE')
		BEGIN
			SELECT
				CAST(NULL AS BIGINT)							AS [StockLineId],
				MAX(R.[LeaseNumber])                            AS [LeaseNumber],
				CASE WHEN COUNT(DISTINCT R.[EngineSn]) > 1 THEN 'Multiple' ELSE MAX(R.[EngineSn]) END AS [EngineSn],
				MAX(R.[BaseModel])                              AS [BaseModel],
				MAX(R.[EngineType])                             AS [EngineType],
				CASE WHEN COUNT(DISTINCT R.[Location]) > 1 THEN 'Multiple' ELSE MAX(R.[Location]) END AS [Location],
				CASE WHEN COUNT(DISTINCT R.[Disposition]) > 1 THEN 'Multiple' ELSE MAX(R.[Disposition]) END AS [Disposition],
				MAX(R.[Lessee])                                 AS [Lessee],
				MAX(R.[LeaseType])                              AS [LeaseType],
				MIN(R.[RentalDate])                             AS [RentalDate],
				MAX(R.[RentalExpiration])                       AS [RentalExpiration],
				MIN(R.[CoiExpiration])                          AS [CoiExpiration],
				MAX(R.[DateUpdated])                            AS [DateUpdated],
				SUM(R.[RentalIncome])                           AS [RentalIncome],
				SUM(R.[MtxExpAc6310])                           AS [MtxExpAc6310],
				SUM(R.[Roi])                                    AS [Roi],
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
				R.[Location],
				R.[Disposition],
				R.[Lessee],
				R.[LeaseType],
				R.[RentalDate],
				R.[RentalExpiration],
				R.[CoiExpiration],
				R.[DateUpdated],
				R.[RentalIncome],
				R.[MtxExpAc6310],
				R.[Roi],
				R.[IsActive]
			FROM #EnginePoolRows R
			ORDER BY R.[EngineSn], R.[StockLineId];
		END

		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolLeaseRentalReport'
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