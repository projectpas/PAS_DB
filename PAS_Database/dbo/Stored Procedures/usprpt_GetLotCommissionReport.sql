
-- ===== PROCEDURE: [dbo].[usprpt_GetLotCommissionReport]   (file: _PAS_DB/PAS_DB/dbo/Stored Procedures/Procs3/usprpt_GetLotCommissionReport.sql) =====
/*************************************************************
 ** File:   [usprpt_GetLotCommissionReport]
 ** Author:  Ayushi Patel
 ** Description: LOT Commission Report - commission earned across all LOTs, filterable by LOT Num, Consignee, PN and Sales date range.
 ** Purpose:
 ** Date:   21-08-2026
 ** PARAMETERS:
 ** RETURN VALUE:
 **************************************************************
  ** Change History
 **************************************************************
  ** S NO   Date            Author          Change Description
 ** --   --------         -------          --------------------------------
    1    21-08-2026     Ayushi Patel         [PN-17565] created
    2    25-08-2026     Ayushi Patel         [PN-17780] Renamed date filters 'From Date'/'To Date' to 'Start Date'/'End Date'

**************************************************************/
CREATE    PROCEDURE [dbo].[usprpt_GetLotCommissionReport]
	@mastercompanyid INT,
	@PageNumber INT = NULL,
	@PageSize INT = NULL,
	@xmlFilter XML = NULL,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

		DECLARE @LotId VARCHAR(100) = NULL,
				@ConsigneeName VARCHAR(256) = NULL,
				@PartNumberId VARCHAR(100) = NULL,
				@Fromdate DATETIME2 = NULL,
				@Todate DATETIME2 = NULL,
				@level1Ids VARCHAR(MAX) = NULL,
				@level2Ids VARCHAR(MAX) = NULL,
				@level3Ids VARCHAR(MAX) = NULL,
				@level4Ids VARCHAR(MAX) = NULL,
				@level5Ids VARCHAR(MAX) = NULL,
				@level6Ids VARCHAR(MAX) = NULL,
				@level7Ids VARCHAR(MAX) = NULL,
				@level8Ids VARCHAR(MAX) = NULL,
				@level9Ids VARCHAR(MAX) = NULL,
				@level10Ids VARCHAR(MAX) = NULL,
				@ColPn VARCHAR(200) = NULL,
				@ColPnDescription VARCHAR(200) = NULL,
				@ColManufacturer VARCHAR(200) = NULL,
				@ColSerialNum VARCHAR(200) = NULL,
				@ColStkLineNum VARCHAR(200) = NULL,
				@ColHowCalculate VARCHAR(200) = NULL,
				@ColCommission VARCHAR(200) = NULL,
				@ColSoNum VARCHAR(200) = NULL,
				@ColLotNum VARCHAR(200) = NULL;

		SELECT
			@LotId = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'LOT Num'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @LotId END,
			@ConsigneeName = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Consignee'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(256)') ELSE @ConsigneeName END,
			@PartNumberId = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') COLLATE Latin1_General_CS_AS = 'PN' COLLATE Latin1_General_CS_AS
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') ELSE @PartNumberId END,
			@Fromdate = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Start Date'
				THEN CONVERT(DATE, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')) ELSE @Fromdate END,
			@Todate = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'End Date'
				THEN CONVERT(DATE, filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)')) ELSE @Todate END,
			@level1Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level1'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level1Ids END,
			@level2Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level2'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level2Ids END,
			@level3Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level3'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level3Ids END,
			@level4Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level4'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level4Ids END,
			@level5Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level5'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level5Ids END,
			@level6Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level6'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level6Ids END,
			@level7Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level7'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level7Ids END,
			@level8Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level8'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level8Ids END,
			@level9Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level9'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level9Ids END,
			@level10Ids = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'Level10'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(MAX)') ELSE @level10Ids END,
			@ColPn = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') COLLATE Latin1_General_CS_AS = 'pn' COLLATE Latin1_General_CS_AS
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColPn END,
			@ColPnDescription = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'pnDescription'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColPnDescription END,
			@ColManufacturer = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'manufacturer'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColManufacturer END,
			@ColSerialNum = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'serialNum'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColSerialNum END,
			@ColStkLineNum = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'stkLineNum'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColStkLineNum END,
			@ColHowCalculate = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'howCalculate'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColHowCalculate END,
			@ColCommission = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'commission'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColCommission END,
			@ColSoNum = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'soNum'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColSoNum END,
			@ColLotNum = CASE WHEN filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') = 'lotNum'
				THEN filterby.value('(FieldValue/text())[1]', 'VARCHAR(200)') ELSE @ColLotNum END
		FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE(filterby)
		
		SET @PartNumberId = CASE WHEN ISNULL(@PartNumberId,'') <> '' AND CAST(@PartNumberId AS BIGINT) > 0 THEN @PartNumberId ELSE NULL END;
		SET @LotId = CASE WHEN ISNULL(@LotId,'') <> '' AND CAST(@LotId AS BIGINT) > 0 THEN @LotId ELSE NULL END;

		DECLARE @AppModuleId INT = 0, @SOModuleId INT = 0;
		SELECT @AppModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'Lot';
		SELECT @SOModuleId = [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'SalesOrder';

		DECLARE @LOT_TransOut_SO VARCHAR(100) = 'Trans Out(SO)';

		-- CustomPaginateFilter.PageNo (C#) is a computed property = First + 1, so @PageNumber here always
		-- arrives 1-based relative to the Angular grid's 0-based row offset ("First") - subtract 1 below.
		SET @PageSize = CASE WHEN NULLIF(@PageSize,0) IS NULL THEN 10 ELSE @PageSize END
		SET @PageNumber = ISNULL(@PageNumber, 1)

		;WITH rptCTE([lotId], [lotNum], [pn], [pnDescription], [manufacturer], [serialNum], [stkLineNum], [howCalculate], [commission], [soNum],
					[level1], [level2], [level3], [level4], [level5], [level6], [level7], [level8], [level9], [level10])
		AS (
			SELECT DISTINCT
				lot.[LotId],
				UPPER(lot.[LotNumber]) AS 'lotNum',
				UPPER(im.[PartNumber]) AS 'pn',
				UPPER(im.[PartDescription]) AS 'pnDescription',
				UPPER(im.[ManufacturerName]) AS 'manufacturer',
				UPPER(sl.[SerialNumber]) AS 'serialNum',
				UPPER(sl.[StockLineNumber]) AS 'stkLineNum',
				(CASE WHEN ISNULL(lc.[IsFixedAmount],0) = 1 THEN 'FIXED AMOUNT'
					  WHEN ISNULL(lc.[IsRevenue],0) = 1 AND ISNULL(lc.[IsMargin],0) = 1 THEN 'REVENUE+MARGIN'
					  WHEN ISNULL(lc.[IsRevenue],0) = 1 THEN 'REVENUE'
					  WHEN ISNULL(lc.[IsMargin],0) = 1 THEN 'MARGIN'
					  WHEN ISNULL(lc.[IsRevenueSplit],0) = 1 THEN 'REVENUE SPLIT'
					  ELSE '' END) AS 'howCalculate',
				ISNULL(ltCal.[CommissionExpense],0) AS 'commission',
				UPPER(so.[SalesOrderNumber]) AS 'soNum',
				UPPER(MSD.[Level1Name]) AS 'level1',
				UPPER(MSD.[Level2Name]) AS 'level2',
				UPPER(MSD.[Level3Name]) AS 'level3',
				UPPER(MSD.[Level4Name]) AS 'level4',
				UPPER(MSD.[Level5Name]) AS 'level5',
				UPPER(MSD.[Level6Name]) AS 'level6',
				UPPER(MSD.[Level7Name]) AS 'level7',
				UPPER(MSD.[Level8Name]) AS 'level8',
				UPPER(MSD.[Level9Name]) AS 'level9',
				UPPER(MSD.[Level10Name]) AS 'level10'
			FROM [dbo].[Lot] lot WITH(NOLOCK)
			INNER JOIN [dbo].[LotTransInOutDetails] ltin WITH(NOLOCK) ON lot.[LotId] = ltin.[LotId]
			INNER JOIN [dbo].[Stockline] sl WITH(NOLOCK) ON ltin.[StockLineId] = sl.[StockLineId]
			INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON sl.[ItemMasterId] = im.[ItemMasterId]
			INNER JOIN [dbo].[LotCalculationDetails] ltCal WITH(NOLOCK) ON ltin.[LotTransInOutId] = ltCal.[LotTransInOutId]
			INNER JOIN [dbo].[SalesOrder] so WITH(NOLOCK) ON ltCal.[ReferenceId] = so.[SalesOrderId]
				AND UPPER(REPLACE(ltCal.[Type],' ','')) = UPPER(REPLACE(@LOT_TransOut_SO,' ',''))
			INNER JOIN [dbo].[SalesOrderPartV1] sop WITH(NOLOCK) ON ltCal.[ChildId] = sop.[SalesOrderPartId] AND so.[SalesOrderId] = sop.[SalesOrderId]
			INNER JOIN [dbo].[LotConsignment] lc WITH(NOLOCK) ON lot.[LotId] = lc.[LotId]
			LEFT JOIN [dbo].[BillingInvoicingItems] sobii WITH(NOLOCK) ON sop.[SalesOrderPartId] = sobii.[SubReferenceId]
				AND ISNULL(sobii.[IsPerformaInvoice],0) = 0 AND sobii.[ModuleId] = @SOModuleId
			LEFT JOIN [dbo].[BillingInvoicing] sobi WITH(NOLOCK) ON so.[SalesOrderId] = sobi.[ReferenceId] AND sobi.[MasterCompanyId] = so.[MasterCompanyId]
				AND ISNULL(sobi.[IsPerformaInvoice],0) = 0 AND ISNULL(sobi.[IsVersionIncrease],0) = 0 AND sobi.[ModuleId] = @SOModuleId
				AND sobi.[BillingInvoicingId] = sobii.[BillingInvoicingId]
			LEFT JOIN [dbo].[LotManagementStructureDetails] MSD WITH(NOLOCK) ON MSD.[ModuleID] = @AppModuleId AND MSD.[ReferenceID] = lot.[LotId]
			WHERE lot.[MasterCompanyId] = @mastercompanyid
			AND (@LotId IS NULL OR lot.[LotId] = @LotId)
			AND (ISNULL(@ConsigneeName,'') = '' OR lc.[ConsigneeName] LIKE '%' + @ConsigneeName + '%')
			AND (@PartNumberId IS NULL OR im.[ItemMasterId] = @PartNumberId)
			AND (@Fromdate IS NULL OR CAST(sobi.[InvoiceDate] AS DATE) >= CAST(@Fromdate AS DATE))
			AND (@Todate IS NULL OR CAST(sobi.[InvoiceDate] AS DATE) <= CAST(@Todate AS DATE))
			AND (ISNULL(@level1Ids,'') = ''  OR MSD.[Level1Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level1Ids,',')))
			AND (ISNULL(@level2Ids,'') = ''  OR MSD.[Level2Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level2Ids,',')))
			AND (ISNULL(@level3Ids,'') = ''  OR MSD.[Level3Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level3Ids,',')))
			AND (ISNULL(@level4Ids,'') = ''  OR MSD.[Level4Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level4Ids,',')))
			AND (ISNULL(@level5Ids,'') = ''  OR MSD.[Level5Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level5Ids,',')))
			AND (ISNULL(@level6Ids,'') = ''  OR MSD.[Level6Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level6Ids,',')))
			AND (ISNULL(@level7Ids,'') = ''  OR MSD.[Level7Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level7Ids,',')))
			AND (ISNULL(@level8Ids,'') = ''  OR MSD.[Level8Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level8Ids,',')))
			AND (ISNULL(@level9Ids,'') = ''  OR MSD.[Level9Id]  IN (SELECT Item FROM DBO.SPLITSTRING(@level9Ids,',')))
			AND (ISNULL(@level10Ids,'') = '' OR MSD.[Level10Id] IN (SELECT Item FROM DBO.SPLITSTRING(@level10Ids,',')))
		)
		,FinalCTE AS (
			SELECT * FROM rptCTE
			WHERE (ISNULL(@ColPn,'') = '' OR [pn] LIKE '%' + UPPER(@ColPn) + '%')
			AND (ISNULL(@ColPnDescription,'') = '' OR [pnDescription] LIKE '%' + UPPER(@ColPnDescription) + '%')
			AND (ISNULL(@ColManufacturer,'') = '' OR [manufacturer] LIKE '%' + UPPER(@ColManufacturer) + '%')
			AND (ISNULL(@ColSerialNum,'') = '' OR [serialNum] LIKE '%' + UPPER(@ColSerialNum) + '%')
			AND (ISNULL(@ColStkLineNum,'') = '' OR [stkLineNum] LIKE '%' + UPPER(@ColStkLineNum) + '%')
			AND (ISNULL(@ColHowCalculate,'') = '' OR [howCalculate] LIKE '%' + UPPER(@ColHowCalculate) + '%')
			AND (ISNULL(@ColCommission,'') = '' OR CAST([commission] AS VARCHAR(50)) LIKE '%' + @ColCommission + '%')
			AND (ISNULL(@ColSoNum,'') = '' OR [soNum] LIKE '%' + UPPER(@ColSoNum) + '%')
			AND (ISNULL(@ColLotNum,'') = '' OR [lotNum] LIKE '%' + UPPER(@ColLotNum) + '%')
		)
		,WithTotal ([totalCommission])
		AS (SELECT FORMAT(SUM([commission]), 'N', 'en-us') FROM FinalCTE)

		SELECT COUNT(1) OVER () AS [TotalRecordsCount],
				ROW_NUMBER() OVER (ORDER BY
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'lotNum') THEN lotNum END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'lotNum') THEN lotNum END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'pn') THEN pn END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'pn') THEN pn END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'pnDescription') THEN pnDescription END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'pnDescription') THEN pnDescription END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'manufacturer') THEN manufacturer END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'manufacturer') THEN manufacturer END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'serialNum') THEN serialNum END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'serialNum') THEN serialNum END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'stkLineNum') THEN stkLineNum END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'stkLineNum') THEN stkLineNum END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'howCalculate') THEN howCalculate END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'howCalculate') THEN howCalculate END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'commission') THEN commission END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'commission') THEN commission END DESC,
					CASE WHEN (@SortOrder = 1  AND @SortColumn = 'soNum') THEN soNum END ASC,
					CASE WHEN (@SortOrder = -1 AND @SortColumn = 'soNum') THEN soNum END DESC,
					FC.[lotId], FC.[pn]) AS [itemNum],
				FC.[pn],
				FC.[pnDescription],
				FC.[manufacturer],
				FC.[serialNum],
				FC.[stkLineNum],
				FC.[howCalculate],
				FORMAT(FC.[commission], 'N2') AS [commission],
				FC.[soNum],
				FC.[lotNum],
				FC.[level1],
				FC.[level2],
				FC.[level3],
				FC.[level4],
				FC.[level5],
				FC.[level6],
				FC.[level7],
				FC.[level8],
				FC.[level9],
				FC.[level10],
				WT.[totalCommission]
		FROM FinalCTE FC
		CROSS JOIN WithTotal WT
		ORDER BY
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'lotNum') THEN lotNum END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'lotNum') THEN lotNum END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'pn') THEN pn END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'pn') THEN pn END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'pnDescription') THEN pnDescription END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'pnDescription') THEN pnDescription END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'manufacturer') THEN manufacturer END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'manufacturer') THEN manufacturer END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'serialNum') THEN serialNum END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'serialNum') THEN serialNum END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'stkLineNum') THEN stkLineNum END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'stkLineNum') THEN stkLineNum END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'howCalculate') THEN howCalculate END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'howCalculate') THEN howCalculate END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'commission') THEN commission END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'commission') THEN commission END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'soNum') THEN soNum END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'soNum') THEN soNum END DESC,
			FC.[lotId]
		OFFSET (@PageNumber - 1) ROWS FETCH NEXT @PageSize ROWS ONLY;

	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
	-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,
            @AdhocComments varchar(150) = '[usprpt_GetLotCommissionReport]',
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(100)) +
            '@Parameter2 = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100)) +
            '@Parameter3 = ''' + CAST(ISNULL(@mastercompanyid, '') AS VARCHAR(100)) +
            '@Parameter4 = ''' + CAST(ISNULL(@xmlFilter, '') AS VARCHAR(MAX)),
            @ApplicationName VARCHAR(100) = 'PAS'

    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC Splogexception @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
	RETURN (1);
	END CATCH
END