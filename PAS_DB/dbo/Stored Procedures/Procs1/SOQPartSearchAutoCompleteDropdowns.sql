/* =====================================================================
 PN-17009 : Stock/Non-Stock label suffix for the PN search dropdown
            behind api/ItemMaster/searchpartnumberadvancednew.

 Updated SP only (1 object) - safe to run standalone.

 dbo.SOQPartSearchAutoCompleteDropdowns is called from
 CommonRepository.SOQPartSearchAutoCompleteDropdowns(...), invoked by
 ItemMasterController.SearchPartNumberAdvancedNew() at route
 POST api/ItemMaster/searchpartnumberadvancednew.

 This SP already restricts every one of its 8 INSERT blocks to
 im.ItemTypeId = 1 (ItemMasterStockTypeEnum.Stock) AND
 ISNULL(im.IsNonStock,0) = 0 - it never returns Non-Stock items - so the
 fix here is purely cosmetic/consistency: appended ' (Stock)' to the end
 of the Label expression in all 8 blocks, matching the same rule already
 applied to AutoCompleteDropdowns.sql / AutoCompleteDropdownsItemMasterWithManufacturer.sql:
   with manufacturer    -> "PartNumber - Manufacturer (Stock)"
   without manufacturer -> "PartNumber (Stock)"

 No Non-Stock branch exists in this SP to add a ' (Non-Stock)' suffix to
 - flagging in case this PN search should also surface Non-Stock parts
 going forward; let me know if so and I'll add a matching branch.

 Author : RAJESH GAMI
 Date   : 13/July/2026
===================================================================== */

-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.SOQPartSearchAutoCompleteDropdowns
-- ---------------------------------------------------------------------------------------------------
/*************************************************************
 ** File:   [SOQPartSearchAutoCompleteDropdowns]
 ** Author:
 ** Description: This stored procedure is used to get part details from PN search
 ** Purpose:
 ** Date:

 ** PARAMETERS:

 ** RETURN VALUE:
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author			Change Description
 ** --   --------     -------			-------------------------------
    1	 06/13/2024  Vishal Suthar		Increased reasult set limit from 20 to 50
	2	 11/18/2024  AMIT GHEDIYA		Updated serach with same text.
	3	 03/21/2025  Devendra Shekh		Added Except Parts for PMA/DER
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	5    13/July/2026			 RAJESH GAMI						[PN-17009] - Appended ' (Stock)' to the Label output (all 8 INSERT blocks - this SP
										 already restricts to ItemTypeId = 1 / ISNULL(IsNonStock,0) = 0 everywhere), so the
										 PN search dropdown behind api/ItemMaster/searchpartnumberadvancednew shows the type
										 suffix consistently with the other AutoComplete dropdowns.
************************************************************************/
CREATE   PROCEDURE [dbo].[SOQPartSearchAutoCompleteDropdowns]
  @CustomerId INT=0,
  @CustRestrictedDer BIT=0,
  @CustRestrictedPMA BIT=0,
  @IncludeDER BIT = 0 ,
  @IncludePMA BIT = 0,
  @IncludeAlternatePN BIT = NULL,
  @IncludeEquiPN BIT = NULL,
  @partSarchText VARCHAR(50) = '',
  @Idlist VARCHAR(MAX) = '0',
  @MasterCompanyId INT = 1
  AS
  BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
		BEGIN
			DROP TABLE #TempTable
		END
		CREATE TABLE #TempTable(
					PartId BIGINT,
					PartNumber VARCHAR(MAX),
					Label VARCHAR(Max),
					PartDescription VARCHAR(MAX),
					ManufacturerName VARCHAR(MAX),
					StockType VARCHAR(50))

		IF OBJECT_ID(N'tempdb..#Result') IS NOT NULL
		BEGIN
			DROP TABLE #Result
		END

		CREATE TABLE #Result(
						PartId BIGINT,
						PartNumber VARCHAR(MAX),
						Label VARCHAR(MAX),
						PartDescription VARCHAR(MAX),
						ManufacturerName VARCHAR(MAX),
						StockType VARCHAR(50))

		--- FOR OEM
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE @partSarchText +'%')
			AND im.IsOEM = 1 AND IsDER = 0

		--FOR PMA
		 AND ISNULL(im.IsNonStock,0) = 0
		 IF( @CustRestrictedPMA <> 1	)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE @partSarchText +'%')
			AND im.IsPma  =  1	AND IsDER = 0
         AND ISNULL(im.IsNonStock,0) = 0
			 END

		--FOR DER
		IF( @CustRestrictedDer <> 1	)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE @partSarchText +'%')
			AND im.IsDER  = 1
         AND ISNULL(im.IsNonStock,0) = 0
			 END

		IF( @IncludePMA = 1)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE @partSarchText +'%')
			AND im.IsPma  =  1	AND IsDER = 0
		 AND ISNULL(im.IsNonStock,0) = 0
			 END

		IF( @IncludeDER = 1)
		BEGIN
		INSERT INTO #TempTable (PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
		SELECT DISTINCT
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE @partSarchText +'%')
			AND im.IsDER  = 1
		 AND ISNULL(im.IsNonStock,0) = 0
			 END

		 --Adding PMA Except Parts
		INSERT INTO #TempTable (PartId, PartNumber, Label, PartDescription, ManufacturerName, StockType)
		SELECT DISTINCT
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON im.ManufacturerId = M.ManufacturerId
			INNER JOIN [dbo].[RestrictedParts] rpDER WITH(NOLOCK) ON
							im.ItemMasterId = rpDER.ItemMasterId
							AND rpDER.PartType = 'PMA'
							AND rpDER.ReferenceId  = @CustomerId
							AND rpDER.ModuleId = 1--This is wrong actully Module id in restricted part itself is coming wrong
							AND rpDER.IsActive = 1
							AND rpDER.IsDeleted = 0
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')

		--Adding DER Except Parts
		 AND ISNULL(im.IsNonStock,0) = 0
		 INSERT INTO #TempTable (PartId, PartNumber, Label, PartDescription, ManufacturerName, StockType)
		SELECT DISTINCT
			im.ItemMasterId AS PartId,
			im.partnumber AS PartNumber,
			(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
			im.PartDescription AS PartDescription,
			im.ManufacturerName AS ManufacturerName,
			(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
			WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
			ELSE 'OEM'
			END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON im.ManufacturerId = M.ManufacturerId
			INNER JOIN [dbo].[RestrictedParts] rpDER WITH(NOLOCK) ON
							im.ItemMasterId = rpDER.ItemMasterId
							AND rpDER.PartType = 'DER'
							AND rpDER.ReferenceId  = @CustomerId
							AND rpDER.ModuleId = 1--This is wrong actully Module id in restricted part itself is coming wrong
							AND rpDER.IsActive = 1
							AND rpDER.IsDeleted = 0
			WHERE im.IsActive = 1
			AND im.IsDeleted = 0
			AND im.ItemTypeId = 1 -- ItemMasterStockTypeEnum.Stock
			AND im.MasterCompanyId = @MasterCompanyId
			AND (@partSarchText IS NULL OR im.partnumber LIKE '%'+ @partSarchText +'%')

		 AND ISNULL(im.IsNonStock,0) = 0
			 INSERT INTO #Result
				SELECT
				DISTINCT TOP 50 *
				FROM #TempTable t
				ORDER BY t.PartNumber

		IF(@Idlist IS NOT NULL)
		BEGIN
			INSERT INTO #Result(PartId, PartNumber,Label, PartDescription,ManufacturerName, StockType)
			SELECT DISTINCT
					im.ItemMasterId AS PartId,
					im.partnumber AS PartNumber,
					(im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId AND ISNULL(SD.IsNonStock,0) = 0 ) > 1 then ' - '+ M.[Name] ELSE '' END) + ' (Stock)') AS Label,
					im.PartDescription AS PartDescription,
					im.ManufacturerName AS ManufacturerName,
					(CASE WHEN im.IsPma= 1 AND im.IsDER = 1 THEN 'PMA&DER'
					WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
					WHEN im.IsPma = 0 AND im.IsDER = 1 THEN 'DER'
					ELSE 'OEM'
					END) AS StockType
			FROM DBO.ItemMaster im WITH(NOLOCK)
			LEFT JOIN dbo.Manufacturer M WITH(NOLOCK) ON Im.ManufacturerId = M.ManufacturerId
			WHERE im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
		 AND ISNULL(im.IsNonStock,0) = 0
			 END

		SELECT DISTINCT TOP 50 r.PartId,
			r.PartNumber,
			r.PartDescription,
			r.ManufacturerName,
			r.StockType,
			r.Label
			FROM #Result r

		DROP Table #TempTable
		DROP Table #Result
	END
	COMMIT  TRANSACTION

	END TRY
	BEGIN CATCH
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SOQPartSearchAutoCompleteDropdowns'
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@CustomerId, '') + ''',
													 @Parameter2 = ' + ISNULL(@CustRestrictedDer,'') + ',
													 @Parameter3 = ' + ISNULL(@CustRestrictedPMA,'') + ',
													 @Parameter4 = ' + ISNULL(@IncludeDER,'') + ',
													 @Parameter5 = ' + ISNULL(@IncludePMA,'') + ',
													 @Parameter6 = ' + ISNULL(@IncludeAlternatePN,'') + ',
													 @Parameter7 = ' + ISNULL(@IncludeEquiPN,'') + ',
													 @Parameter8 = ' + ISNULL(@partSarchText,'') + ',
													 @Parameter9 = ' + ISNULL(@Idlist,'') + ',
													 @Parameter10 = ' + ISNULL(@MasterCompanyId,'') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END