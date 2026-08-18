
/*************************************************************
 ** File:		[dbo].[USP_GetPartDetailsWithmasterCompanyIdAllTypes]
 ** Author:		Rajesh Gami
 ** Description: Stock + Non-Stock variant of [USP_GetPartDetailsWithmasterCompanyId], used ONLY by
				 the Purchase Order "Add Multiple PN" search so it can return BOTH Stock (ItemTypeId=1)
				 and Non-Stock (ItemTypeId=2) rows from ItemMaster. This is a NEW, separate procedure
				 so the existing [USP_GetPartDetailsWithmasterCompanyId] (Stock-only, also consumed by
				 the Repair Order and Vendor RFQ-PO "Add Multiple PN" searches) is left completely
				 untouched/unaffected.
 ** Purpose:
 ** Date:   15/July/2026
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date				Author				Change Description
 ** --   -------------		----------------	-------------------
	1	15/July/2026		RAJESH GAMI			[PN-17009] - Created. Stock + Non-Stock unified variant
													of USP_GetPartDetailsWithmasterCompanyId for the PO
													Setup "Add Multiple PN" flow (ItemMasterNonStock has
													been merged into ItemMaster / IsNonStock flag).
													Replaced the "AND ISNULL(IM.IsNonStock,0) = 0"
													(Stock-only) filter with "AND IM.ItemTypeId IN (1,2)"
													so both Stock and Non-Stock rows are returned;
													Equipment/Asset item types remain excluded.

	EXEC [USP_GetPartDetailsWithmasterCompanyIdAllTypes] 'Part9,part,199999,test',1
	EXEC [USP_GetPartDetailsWithmasterCompanyIdAllTypes] 'a',1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetPartDetailsWithmasterCompanyIdAllTypes]
@PartsList VARCHAR(MAX),
@MasterCompanyId BIGINT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY

	DECLARE @MINID BIGINT;
	DECLARE @MAXID BIGINT;
	DECLARE @PartNo VARCHAR(250)='';

	IF OBJECT_ID('tempdb..#tmpPartsResults') IS NOT NULL
		DROP TABLE #tmpPartsResults;

	;WITH cte AS (
		SELECT DISTINCT TRIM(value) AS Parts
		FROM STRING_SPLIT(@PartsList, ',')
	)
	SELECT
		ROW_NUMBER() OVER (ORDER BY Parts) AS RowID,
	Parts
	INTO #tmpPartsResults
	FROM cte;

	SELECT @MinId = MIN(RowID), @MaxId = MAX(RowID) FROM #tmpPartsResults;

	IF OBJECT_ID(N'tempdb..#tmpParts') IS NOT NULL
		DROP TABLE #tmpParts;

	IF OBJECT_ID(N'tempdb..#tmpPartsNotFound') IS NOT NULL
		DROP TABLE #tmpPartsNotFound

	CREATE TABLE #tmpParts
	(
		PartNumber VARCHAR(50) NULL,
		PartAlternatePartId BIGINT NULL,
		PartDescription NVARCHAR(max) NULL,
		ManufacturerId BIGINT NULL,
		Manufacturer VARCHAR(250) NULL,
		ReorderQuantiy INT NULL,
		ItemTypeId INT NULL,
		ItemMasterId BIGINT NULL,
		IsHazardousMaterial BIT NULL,
		PriorityId BIGINT NULL,
		NSN VARCHAR(50) NULL,
		[Priority] VARCHAR(100) NULL,
		StockType VARCHAR(max) NULL,
	);

	CREATE TABLE #tmpPartsNotFound
	(
		PartNumber VARCHAR(50) NULL,
	);

	WHILE @MinId <= @MaxId
	BEGIN
		SELECT @PartNo = Parts
        FROM #tmpPartsResults
        WHERE RowID = @MinId;

		INSERT INTO #tmpParts
		(
			[PartNumber],[PartAlternatePartId],[PartDescription],[ManufacturerId],[Manufacturer],[ReorderQuantiy],[ItemTypeId],[ItemMasterId],[IsHazardousMaterial],
			[PriorityId],[NSN],[Priority],[StockType]
		)
		SELECT
			IM.PartNumber,IM.PartAlternatePartId,IM.PartDescription,IM.ManufacturerId,MF.[Name],IM.ReorderQuantiy,IM.ItemTypeId,IM.ItemMasterId,IM.IsHazardousMaterial,
			IM.PriorityId,IM.NationalStockNumber,
			ISNULL(P.[Description], ''),
			CASE
				WHEN IM.IsPma = 1 AND IM.IsDER = 1 THEN 'PMA&DER'
				WHEN IM.IsPma = 1 AND IM.IsDER = 0 THEN 'PMA'
				WHEN IM.IsPma = 0 AND IM.IsDER = 1 THEN 'DER'
				ELSE 'OEM'
			END
		FROM [DBO].ItemMaster IM WITH(NOLOCK)
		LEFT JOIN  [DBO].Manufacturer MF WITH(NOLOCK) ON  IM.ManufacturerId = MF.ManufacturerId
		LEFT JOIN [DBO].[Priority] P WITH(NOLOCK) ON IM.PriorityId = P.PriorityId
		WHERE IM.PartNumber = @PartNo AND  IM.IsActive =1 AND IM.IsDeleted = 0 AND IM.MasterCompanyId = @MasterCompanyId
		 IF NOT EXISTS(SELECT 1 FROM dbo.ItemMaster IM WITH(NOLOCK) WHERE IM.PartNumber = @PartNo AND IM.IsActive = 1 AND IM.IsDeleted = 0 AND IM.MasterCompanyId = @MasterCompanyId)
        BEGIN
            INSERT INTO #tmpPartsNotFound (PartNumber)
            VALUES (@PartNo);
        END

		SET @MinId = @MinId + 1;
	END

	SELECT [PartNumber],[PartAlternatePartId],[PartDescription],[ManufacturerId],[Manufacturer],[ReorderQuantiy],[ItemTypeId],[ItemMasterId],[IsHazardousMaterial],
		   [PriorityId],[NSN],[Priority],[StockType]
	FROM #tmpParts
	SELECT [PartNumber] FROM #tmpPartsNotFound

	END TRY
	BEGIN CATCH
	IF @@trancount > 0
		ROLLBACK TRAN;
		DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetPartDetailsWithmasterCompanyIdAllTypes]'
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
		RETURN (1);
	END CATCH
END