/*************************************************************
 ** File:   [USP_GetLeaseEnginePoolGeneralInfoReport]
 ** Description: Lease Report (Engine Pool) - "General Info" tab. One row per engine (stockline).
 **              The main table is the Lease : LeaseStockline (latest non-deleted lease line of each engine stockline) + LeaseHeader, joined to the Stockline.
 **              Only the columns whose source is known are filled; every other column of the tab is returned
 **              as NULL (blank in the grid) until its source is agreed.
 ** Purpose: Leasing > Reports > Lease Report > General Info 
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date			Author				Change Description
 ** -----------------------------------------------------------
    1    30/10/2026		Kishor Makwana		[PN-18419] - Created
    
-- EXEC [dbo].[USP_GetLeaseEnginePoolGeneralInfoReport] @MasterCompanyId = 1, @IsActive = 1, @ViewType = 'PN'
************************************************************************/
CREATE PROCEDURE [dbo].[USP_GetLeaseEnginePoolGeneralInfoReport]
	@MasterCompanyId INT,
	@IsActive BIT = 1,
	@ItemGroup VARCHAR(256) = NULL,
	@ViewType VARCHAR(10) = 'PN',
	@AsOfDate DATETIME2(7) = NULL
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
		-- NBV is calculated as of the report run date (not used yet: the NBV column is the stockline unit cost for now)
		SET @AsOfDate = ISNULL(@AsOfDate, GETUTCDATE());

		IF OBJECT_ID('tempdb..#EnginePoolRows') IS NOT NULL DROP TABLE #EnginePoolRows;

		SELECT
			STK.[StockLineId]								AS [StockLineId],
			LH.[LeaseNumber]								AS [LeaseNumber],
			STK.[PartNumber]								AS [EngineSn],
			CAST(NULL AS VARCHAR(200))						AS [BaseModel],
			CAST(NULL AS VARCHAR(200))						AS [EngineType],
			CASE WHEN STK.[OwnerType] = 1 THEN CUS.[Name]
				 WHEN STK.[OwnerType] = 2 THEN VEN.[VendorName]
				 WHEN STK.[OwnerType] = 9 THEN LE.[Name]
				 ELSE STK.[OwnerName] END					AS [Owner],
			LOC.[Name]										AS [Location],
			CAST(NULL AS VARCHAR(200))						AS [Disposition],
			LCUS.[Name]										AS [Lessee],
			CAST(NULL AS VARCHAR(200))						AS [SpecSheet],
			STK.[TagDate]									AS [TraceDate],
			CAST(NULL AS DECIMAL(18, 2))					AS [RetailValue],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValue],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValueIncluded],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValueExcluded],
			CAST(NULL AS DECIMAL(18, 2))					AS [WholesaleValueDoubtful],
			COALESCE(NULLIF(LTRIM(RTRIM(LSL.[Notes])), ''), NULLIF(LTRIM(RTRIM(LH.[Memo])), ''), NULLIF(LTRIM(RTRIM(LH.[Notes])), ''))	AS [Remarks],
			PO.[OpenDate]									AS [PurchaseDate],
			STK.[PurchaseOrderUnitCost]						AS [PurchasePrice],
			STK.[UnitCost]									AS [Nbv],
			CAST(NULL AS VARCHAR(200))						AS [LongTermPreserveExpDate],
			LSL.[UpdatedDate]								AS [DateUpdated],
			CAST(NULL AS VARCHAR(200))						AS [Lienholder],
			PO.[VendorName]									AS [Vendor],
			TCH.[TotalTSN]									AS [TsnAtPurchase],
			TCH.[TotalCSN]									AS [CsnAtPurchase],
			CAST(NULL AS DECIMAL(18, 6))					AS [TsoCamAtPurchase],
			STK.[isActive]									AS [IsActive],
			LSL.[LeaseHeaderId]								AS [LeaseHeaderId]
		INTO #EnginePoolRows
		FROM (
				SELECT LS.[StockLineId], LS.[LeaseHeaderId], LS.[Notes], LS.[UpdatedDate],
					LS.[LeaseStocklineId],
					ROW_NUMBER() OVER (PARTITION BY LS.[StockLineId] ORDER BY ISNULL(LS.[StartDate], '1900-01-01') DESC, LS.[LeaseStocklineId] DESC) AS [RN]
				FROM [dbo].[LeaseStockline] LS WITH (NOLOCK)
				WHERE LS.[MasterCompanyId] = @MasterCompanyId AND ISNULL(LS.[IsDeleted], 0) = 0
			) LSL
			INNER JOIN [dbo].[LeaseHeader] LH WITH (NOLOCK) ON LH.[LeaseHeaderId] = LSL.[LeaseHeaderId] AND ISNULL(LH.[IsDeleted], 0) = 0
			INNER JOIN [dbo].[Stockline] STK WITH (NOLOCK) ON STK.[StockLineId] = LSL.[StockLineId]
			LEFT JOIN [dbo].[Customer] LCUS WITH (NOLOCK) ON LCUS.[CustomerId] = LH.[CustomerId]
			LEFT JOIN [dbo].[Location] LOC WITH (NOLOCK) ON LOC.[LocationId] = STK.[LocationId]
			LEFT JOIN [dbo].[PurchaseOrder] PO WITH (NOLOCK) ON PO.[PurchaseOrderId] = STK.[PurchaseOrderId]
			LEFT JOIN [dbo].[Customer] CUS WITH (NOLOCK) ON STK.[OwnerType] = 1 AND CUS.[CustomerId] = STK.[Owner]
			LEFT JOIN [dbo].[Vendor] VEN WITH (NOLOCK) ON STK.[OwnerType] = 2 AND VEN.[VendorId] = STK.[Owner]
			LEFT JOIN [dbo].[LegalEntity] LE WITH (NOLOCK) ON STK.[OwnerType] = 9 AND LE.[LegalEntityId] = STK.[Owner]
			OUTER APPLY (
				SELECT TOP 1 H.[TotalTSN], H.[TotalCSN]
				FROM [dbo].[StocklineTimeCycleHistory] H WITH (NOLOCK)
				WHERE H.[StocklineId] = STK.[StockLineId] AND ISNULL(H.[IsDeleted], 0) = 0
				ORDER BY H.[StocklineTimeCycleHistoryId] ASC
			) TCH
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
				CASE WHEN COUNT(DISTINCT R.[Owner]) > 1 THEN 'Multiple' ELSE MAX(R.[Owner]) END AS [Owner],
				CASE WHEN COUNT(DISTINCT R.[Location]) > 1 THEN 'Multiple' ELSE MAX(R.[Location]) END AS [Location],
				CASE WHEN COUNT(DISTINCT R.[Disposition]) > 1 THEN 'Multiple' ELSE MAX(R.[Disposition]) END AS [Disposition],
				MAX(R.[Lessee])                                 AS [Lessee],
				MAX(R.[SpecSheet])                              AS [SpecSheet],
				MAX(R.[TraceDate])                              AS [TraceDate],
				SUM(R.[RetailValue])                            AS [RetailValue],
				SUM(R.[WholesaleValue])                         AS [WholesaleValue],
				SUM(R.[WholesaleValueIncluded])                 AS [WholesaleValueIncluded],
				SUM(R.[WholesaleValueExcluded])                 AS [WholesaleValueExcluded],
				SUM(R.[WholesaleValueDoubtful])                 AS [WholesaleValueDoubtful],
				MAX(R.[Remarks])                                AS [Remarks],
				MIN(R.[PurchaseDate])                           AS [PurchaseDate],
				SUM(R.[PurchasePrice])                          AS [PurchasePrice],
				SUM(R.[Nbv])                                    AS [Nbv],
				MAX(R.[LongTermPreserveExpDate])                AS [LongTermPreserveExpDate],
				MAX(R.[DateUpdated])                            AS [DateUpdated],
				MAX(R.[Lienholder])                             AS [Lienholder],
				CASE WHEN COUNT(DISTINCT R.[Vendor]) > 1 THEN 'Multiple' ELSE MAX(R.[Vendor]) END AS [Vendor],
				SUM(R.[TsnAtPurchase])                          AS [TsnAtPurchase],
				SUM(R.[CsnAtPurchase])                          AS [CsnAtPurchase],
				SUM(R.[TsoCamAtPurchase])                       AS [TsoCamAtPurchase],
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
				R.[Owner],
				R.[Location],
				R.[Disposition],
				R.[Lessee],
				R.[SpecSheet],
				R.[TraceDate],
				R.[RetailValue],
				R.[WholesaleValue],
				R.[WholesaleValueIncluded],
				R.[WholesaleValueExcluded],
				R.[WholesaleValueDoubtful],
				R.[Remarks],
				R.[PurchaseDate],
				R.[PurchasePrice],
				R.[Nbv],
				R.[LongTermPreserveExpDate],
				R.[DateUpdated],
				R.[Lienholder],
				R.[Vendor],
				R.[TsnAtPurchase],
				R.[CsnAtPurchase],
				R.[TsoCamAtPurchase],
				R.[IsActive]
			FROM #EnginePoolRows R
			ORDER BY R.[EngineSn], R.[StockLineId];
		END

		DROP TABLE #EnginePoolRows;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = DB_NAME()

-------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			, @AdhocComments VARCHAR(150) = 'USP_GetLeaseEnginePoolGeneralInfoReport'
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