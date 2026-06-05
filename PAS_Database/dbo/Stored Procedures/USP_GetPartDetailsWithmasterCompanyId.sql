/*************************************************************           
 ** File:		[dbo].[USP_GetPartDetailsWithmasterCompanyI       
 ** Author:		 Nakul Chandigra
 ** Description: This stored procedure retrieves part details for the Add Multiple Part search in a PO, filtered by MasterCompanyId.
 ** Purpose:         
 ** Date:   02-12-2025 
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date				Author				Change Description            
 ** --   -------------		----------------	-------------------         
	1	02-12-2025           Nakul Chandigra     Created 
	2	05-06-2026           Priyansh Patel     Uom changes of ReorderQuantiy int to decimal [PN-16746]


	EXEC [USP_GetPartDetailsWithId] 'Part9,part,199999,test',1 
	EXEC [USP_GetPartDetailsWithId] 'a',1
**************************************************************/
CREATE    PROCEDURE [dbo].[USP_GetPartDetailsWithmasterCompanyId]
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
		ReorderQuantiy DECIMAL(18,6) NULL,
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
              , @AdhocComments     VARCHAR(150)    = '[dbo].[USP_GetPartDetailsWithmasterCompanyI'
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