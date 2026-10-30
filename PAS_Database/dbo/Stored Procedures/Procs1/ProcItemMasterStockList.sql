/*********************           
 ** File:   [ProcItemMasterStockList]          
 ** Author:  
 ** Description: 
 ** Purpose:         
 ** Date:   09 Nov 2023      
          
 ** RETURN VALUE:           
  
 **********************           
  ** Change History           
 **********************           
 ** PR   Date             Author		         Change Description            
 ** --   --------         -------		     ----------------------------       
   
    2    23 Nov 2023    BHARGAV SALIYA       Add HasSubAssy  
	3    17 July 2024   Shrey Chandegara     Modified( use this function @CurrntEmpTimeZoneDesc for date issue.)
	1    28/01/2025     Ayushi Patel         converted the date into utc (created , updated) , Added a case to get timeZone
	2	 14/02/2025		Ayushi Patel		 Resolve sorting related issue (createdDates)
	3    06-03-2025     Shrey Chandegara     Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
	4    01-Aug-2025    Bhargav saliya       Modified [HasSubAssy] field Conditon 
	5	 07-Aug-2025	Ayushi Patel		 added condition for IsOEM
	6	 21-Aug-2025	Bhargav saliya		 added Ranking
	7   04-Sep-2025    Sahdev Saliya        Added WorkOrderType
	8   09-Sep-2025    Sahdev Saliya        Added Filter For RankingsName And WorkOrderType
	9   12-Nov-2025    Divyesh Kathiriya    Update HasSubAssy only return 'WoSubAssy' value due to column name change.
	10   14-Nov-2025    Divyesh Kathiriya     Get RoSubAssy.
	11   27-May-2026    Sahdev Saliya        Added Model [PN-16353]
	12   29-Jun-2026    Rajesh Gami			 Merging the NonStock Inventory to Inventory [PN-17008]
	13   03-Aug-2026    Rajesh Gami          Ported from BETA: added @IntegrationTypeId/@ItemTypeStatusId
	14   08-03-2026    Rajesh Gami      Performance pass: removed per-row scalar UDF call
	15   03-Aug-2026    Sahdev Saliya        Added IsKitAssy [PN-17371]
	16   10-Sep-2026   Bhargav Saliya    [PN-17849] Part Number filter: normalize dashes(-)/slashes("\","/")/underscore(_)
	17   26-Oct-2026   Rajesh Gami       [PN-18406] Asset item type: ItemType = 'Asset' when IsAsset = 1, IsAsset column, Item Type filter 11 = Asset
	18   29-Oct-2026   Rajesh Gami       [PN-18450] Performance: light rows from covering index; PartDescription / HasSubAssy / RoSubAssy / Ranking only for the page rows (unless filtered / sorted)

**********************/
CREATE   PROCEDURE [dbo].[ProcItemMasterStockList]
@PageNumber int = NULL,
@PageSize int = NULL,
@SortColumn varchar(50)=NULL,
@SortOrder int = NULL,
@GlobalFilter varchar(50) = NULL,
@StatusId int = NULL,
@IsHazardousMaterial  varchar(50) = NULL,
@PartNumber varchar(50) = NULL,
@PartDescription varchar(50) = NULL,
@Manufacturerdesc varchar(50) = NULL,
@Classificationdesc varchar(50) = NULL,
@ItemGroup varchar(50) = NULL,
@NationalStockNumber varchar(50) = NULL,
@IsSerialized varchar(50) = NULL,
@IsTimeLife varchar(50) = NULL,
@HasSubAssy varchar(50) = NULL,
@StockType varchar(50) = NULL,
@ItemType varchar(50) = NULL,
@CreatedBy  varchar(50) = NULL,
@CreatedDate datetime = NULL,
@UpdatedBy  varchar(50) = NULL,
@UpdatedDate  datetime = NULL,
@IsDeleted bit = NULL,
@MasterCompanyId bigint = NULL,
@EmployeeId bigint,
@IsUpdated BIT = NULL,
@WorkOrderFormTypeId INT = NULL,
@RankingsName VARCHAR(50) = NULL,
@workOrderType VARCHAR(50) = NULL,
@RoSubAssy varchar(50) = NULL,
@Model varchar(200) = NULL,
@IntegrationTypeId BIGINT = NULL,
@ItemTypeStatusId varchar(50) = NULL,
@IsKitAssy varchar(5) = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		BEGIN TRY

		DECLARE @RecordFrom int;
		DECLARE @IsActive bit;
		--DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		--SELECT @CurrntEmpTimeZoneDesc = TZ.[Description] FROM DBO.LegalEntity LE WITH (NOLOCK) INNER JOIN DBO.TimeZone TZ WITH (NOLOCK) ON LE.TimeZoneId = TZ.TimeZoneId
		DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
		-- PERF FIX: also resolve the numeric UTC offset here, once, alongside the description, so
		-- the CTE below can use DATEADD directly instead of calling DBO.ConvertUTCtoLocal per row
		-- (that function re-queries dbo.TimeZone on every call and forces row-by-row execution).
		DECLARE @BaseUtcOffsetSec INT = 0;

				SELECT
						@CurrntEmpTimeZoneDesc = COALESCE(
							ETZ.[Description],  -- Prefer Employee's TimeZone description if available
							LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
						),
						@BaseUtcOffsetSec = COALESCE(ETZ.BaseUtcOffsetSec, LTZ.BaseUtcOffsetSec, 0)
					FROM
						dbo.Employee E WITH (NOLOCK)
					LEFT JOIN
						dbo.TimeZone ETZ WITH (NOLOCK)
						ON E.TimeZoneId = ETZ.TimeZoneId
					LEFT JOIN
						dbo.LegalEntity LE WITH (NOLOCK)
						ON E.LegalEntityId = LE.LegalEntityId
					LEFT JOIN
						dbo.TimeZone LTZ WITH (NOLOCK)
						ON LE.TimeZoneId = LTZ.TimeZoneId
					WHERE
						E.EmployeeId = @EmployeeId; -- Use appropriate filter for the specific employee

		SET @RecordFrom = (@PageNumber-1)*@PageSize;
		SET @ItemTypeStatusId = CASE WHEN ISNUMERIC(@ItemTypeStatusId) = 1 AND CAST(@ItemTypeStatusId AS INT) > 0 THEN @ItemTypeStatusId ELSE NULL END
		IF @IsDeleted IS NULL
		BEGIN
			SET @IsDeleted=0
		END
		IF @SortColumn IS NULL
		BEGIN
			SET @SortColumn=UPPER('CreatedDate')
		END 
		ELSE
		BEGIN 
			Set @SortColumn=UPPER(@SortColumn)
		END	
		IF(@StatusId=0)
		BEGIN
			SET @IsActive=0;
		END
		ELSE IF(@StatusId=1)
		BEGIN
			SET @IsActive=1;
		END
		ELSE
		BEGIN
			SET @IsActive=NULL;
		END
		IF(@IsHazardousMaterial='')
		BEGIN
			SET @IsHazardousMaterial=NULL;
		END
		/* [PN-18450] Performance (list took ~7 sec):
		   - the wide ItemMaster row (NVARCHAR(MAX) PartDescription, IsAsset, IsKitAssy ...) is no longer read for every row;
		     the light rows come from the covering index IX_ItemMaster_MasterCompanyId_IsDeleted_IsActive_Perf
		   - PartDescription, HasSubAssy, RoSubAssy and Ranking are computed ONLY for the returned page rows,
		     unless a filter / global filter / sort needs them (then for all rows, as before)
		   Same parameters, same output columns, same filters and sort. */
		DECLARE @NeedAll BIT = CASE WHEN ISNULL(@GlobalFilter,'') <> '' OR ISNULL(@PartDescription,'') <> ''
		                              OR ISNULL(@HasSubAssy,'') <> '' OR ISNULL(@RoSubAssy,'') <> '' OR ISNULL(@RankingsName,'') <> ''
		                              OR @SortColumn IN ('PARTDESCRIPTION','HASSUBASSY','ROSUBASSY','RANKINGSNAME')
		                            THEN 1 ELSE 0 END;

		DROP TABLE IF EXISTS #Base, #Target, #Extra, #Page;

		CREATE TABLE #Page  (Seq INT IDENTITY(1,1) PRIMARY KEY, ItemMasterId BIGINT NOT NULL, NumberOfItems INT NOT NULL);
		CREATE TABLE #Extra (ItemMasterId BIGINT NOT NULL PRIMARY KEY, PartDescription NVARCHAR(MAX) NULL, HasSubAssy VARCHAR(3) NULL, RoSubAssy VARCHAR(3) NULL, RankingsName NVARCHAR(MAX) NULL);

		/* light rows (no PartDescription / HasSubAssy / RoSubAssy / Ranking) */
		SELECT im.ItemMasterId,
		       im.PartNumber,
			   (ISNULL(im.ManufacturerName,'')) 'Manufacturerdesc',
			   im.ItemClassificationName 'Classificationdesc',
			   (ISNULL(im.ItemGroup,'')) 'ItemGroup',
			   im.NationalStockNumber,
			   CASE WHEN im.IsSerialized = 1 THEN 'Yes' ELSE 'No' END AS IsSerialized,
			   CASE WHEN im.IsTimeLife = 1 THEN 'Yes' ELSE 'No' END AS IsTimeLife,
			   im.IsActive,
			   ItemType = CASE WHEN ISNULL(im.IsAsset,0) = 1 THEN 'Asset' WHEN im.ItemTypeId = 1 THEN 'Stock' ELSE 'NonStock' END,
			   CAST(im.IsHazardousMaterial AS varchar) 'IsHazardousMaterial',
			   StockType = (CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER'
								 WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
			                     WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER'
								 WHEN im.IsOEM = 1 THEN 'OEM'
								 ELSE ''
							END),
			   im.CreatedDate CreatedDates,
			   CAST(DATEADD(SECOND, @BaseUtcOffsetSec, im.CreatedDate) AS Date) AS CreatedDate,
			   CAST(DATEADD(SECOND, @BaseUtcOffsetSec, im.UpdatedDate) AS Date) AS UpdatedDate,
			   im.CreatedBy,
               im.UpdatedBy,
			   im.IsDeleted,
			   CASE WHEN im.WorkOrderFormTypeId = 1 THEN 'Dynamic' WHEN im.WorkOrderFormTypeId = 2 THEN 'Static' ELSE 'At WO creation' END AS workOrderType,
			   ISNULL(IM.IsNonStock,0)IsNonStock,
			   CAST(ISNULL(im.IsAsset,0) AS BIT) AS IsAsset,
			   im.ItemTypeId,
			   im.Model,
			   CASE WHEN im.IsKitAssy = 1 THEN 'Yes' ELSE 'No' END AS IsKitAssy
		INTO #Base
		FROM dbo.ItemMaster im WITH (NOLOCK)
		WHERE ((im.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR im.IsActive=@IsActive) AND (@IsHazardousMaterial IS NULL OR im.IsHazardousMaterial=@IsHazardousMaterial))
			AND im.MasterCompanyId=@MasterCompanyId
			AND (@ItemTypeStatusId IS NULL
			     -- [PN-18406] 11 = ItemTypeEnum.Asset in the UI filter -> Item Master rows with IsAsset = 1
			     OR (CAST(@ItemTypeStatusId AS INT) = 11 AND ISNULL(im.IsAsset,0) = 1)
			     OR (CAST(@ItemTypeStatusId AS INT) <> 11 AND im.ItemTypeId = CAST(@ItemTypeStatusId AS INT) AND ISNULL(im.IsAsset,0) = 0))
			AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(im.IsUpdated,0) = ISNULL(@IsUpdated,0))
			AND (@IntegrationTypeId IS NULL OR im.IntegrationTypeId = @IntegrationTypeId)
		OPTION (RECOMPILE);

		CREATE UNIQUE CLUSTERED INDEX IX_Base_ItemMasterId ON #Base (ItemMasterId);

		DECLARE @Step INT = 1;
		WHILE @Step <= 2
		BEGIN
			IF ((@NeedAll = 1 AND @Step = 1) OR (@NeedAll = 0 AND @Step = 2))
			BEGIN
				/* HEAVY step: all light rows when a filter / sort needs the heavy columns, otherwise only the page rows */
				TRUNCATE TABLE #Extra;
				SELECT ItemMasterId INTO #Target FROM #Base WHERE @NeedAll = 1
				UNION ALL
				SELECT ItemMasterId FROM #Page WHERE @NeedAll = 0
				OPTION (RECOMPILE);

				INSERT INTO #Extra (ItemMasterId, PartDescription, HasSubAssy, RoSubAssy, RankingsName)
				SELECT T.ItemMasterId,
				       im.PartDescription,
				       CASE WHEN EXISTS (SELECT 1 FROM [DBO].[Assemply] AP WITH (NOLOCK) WHERE AP.ItemMasterId = T.ItemMasterId AND AP.PopulateWoMaterialList = 1) THEN 'Yes' ELSE 'No' END,
				       CASE WHEN EXISTS (SELECT 1 FROM [DBO].[RepairOrderAssembly] RAP WITH (NOLOCK) WHERE RAP.ItemMasterId = T.ItemMasterId) THEN 'Yes' ELSE 'No' END,
				       RK.Ranking
				FROM #Target T
				INNER JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = T.ItemMasterId
				LEFT JOIN (
					SELECT mp.ItemMasterId, STRING_AGG(CAST(R.[Description] AS NVARCHAR(MAX)), ',') AS Ranking
					FROM dbo.ItemMasterRanking mp WITH(NOLOCK)
					INNER JOIN dbo.Ranking R WITH(NOLOCK) ON mp.RankingId = R.RankingId
					WHERE mp.RankingId IS NOT NULL AND mp.ItemMasterId IN (SELECT ItemMasterId FROM #Target)
					GROUP BY mp.ItemMasterId
				) RK ON RK.ItemMasterId = T.ItemMasterId
				OPTION (RECOMPILE);

				DROP TABLE #Target;
			END
			ELSE
			BEGIN
				/* PAGE step: filter + sort + page on the light rows (heavy columns come from #Extra when it is filled) */
				;WITH Src AS (
					SELECT B.*, X.PartDescription, X.HasSubAssy, X.RoSubAssy, X.RankingsName
					FROM #Base B
					LEFT JOIN #Extra X ON X.ItemMasterId = B.ItemMasterId
				),
				FilteredResult AS (
				SELECT *, COUNT(*) OVER() AS NumberOfItems
				FROM Src
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%' OR dbo.fn_NormalizePartNumber(PartNumber) LIKE '%' + dbo.fn_NormalizePartNumber(@GlobalFilter) + '%') OR
			        (PartDescription LIKE '%' +@GlobalFilter+'%') OR	
					(Manufacturerdesc LIKE '%' +@GlobalFilter+'%') OR					
					(Classificationdesc LIKE '%' +@GlobalFilter+'%') OR						
					(ItemGroup LIKE '%' +@GlobalFilter+'%') OR						
					(NationalStockNumber LIKE '%' +@GlobalFilter+'%') OR										
					(IsSerialized LIKE '%' +@GlobalFilter+'%') OR
					(IsTimeLife LIKE '%' +@GlobalFilter+'%') OR
					(HasSubAssy LIKE '%' +@GlobalFilter+'%') OR
					(ItemType LIKE '%' +@GlobalFilter+'%') OR
					--(IsHazardousMaterial LIKE '%' +@GlobalFilter+'%') OR					
					(StockType LIKE '%' +@GlobalFilter+'%') OR
					(CreatedBy LIKE '%' +@GlobalFilter+'%') OR
					(UpdatedBy LIKE '%' +@GlobalFilter+'%') OR
					(RankingsName LIKE '%' +@GlobalFilter+'%') OR
					(workOrderType LIKE '%' +@GlobalFilter+'%') OR
					(RoSubAssy LIKE '%' +@GlobalFilter+'%') OR
					(Model LIKE '%' +@GlobalFilter+'%') OR
					(IsKitAssy LIKE '%' +@GlobalFilter+'%')))
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%' OR dbo.fn_NormalizePartNumber(PartNumber) LIKE '%' + dbo.fn_NormalizePartNumber(@PartNumber) + '%') AND
					(ISNULL(@PartDescription,'') ='' OR PartDescription LIKE '%' + @PartDescription + '%') AND
					(ISNULL(@Manufacturerdesc,'') ='' OR Manufacturerdesc LIKE '%' + @Manufacturerdesc + '%') AND
					(ISNULL(@Classificationdesc,'') ='' OR Classificationdesc LIKE '%' + @Classificationdesc + '%') AND
					(ISNULL(@ItemGroup,'') ='' OR ItemGroup LIKE '%' + @ItemGroup + '%') AND
					(ISNULL(@NationalStockNumber,'') ='' OR NationalStockNumber LIKE '%' + @NationalStockNumber + '%') AND				
					(ISNULL(@IsSerialized,'') ='' OR IsSerialized LIKE '%' + @IsSerialized + '%') AND
					(ISNULL(@IsTimeLife,'') ='' OR IsTimeLife LIKE '%' + @IsTimeLife + '%') AND
					(ISNULL(@HasSubAssy,'') ='' OR HasSubAssy LIKE '%' + @HasSubAssy + '%') AND
					(ISNULL(@ItemType,'') ='' OR ItemType LIKE '%' + @ItemType + '%') AND
					--(ISNULL(@IsHazardousMaterial,'') ='' OR IsHazardousMaterial LIKE '%' + @IsHazardousMaterial + '%') AND					
					(ISNULL(@StockType,'') ='' OR StockType LIKE '%' + @StockType + '%') AND	
					(ISNULL(@CreatedBy,'') ='' OR CreatedBy LIKE '%' + @CreatedBy + '%') AND
					(ISNULL(@UpdatedBy,'') ='' OR UpdatedBy LIKE '%' + @UpdatedBy + '%') AND						
					--(ISNULL(@CreatedDate,'') ='' OR CAST(DBO.ConvertUTCtoLocal(CreatedDate, @CurrntEmpTimeZoneDesc )AS date)=CAST(@CreatedDate AS date)) AND
					(ISNULL(@CreatedDate,'') ='' OR CAST(CreatedDate AS date)=CAST(@CreatedDate AS date))AND
					(ISNULL(@UpdatedDate,'') ='' OR CAST(UpdatedDate AS date)=CAST(@UpdatedDate AS date))AND
				    (ISNULL(@RankingsName,'') ='' OR RankingsName LIKE '%' + @RankingsName + '%') AND
					(ISNULL(@workOrderType,'') ='' OR workOrderType LIKE '%' + @workOrderType + '%') AND
					(ISNULL(@RoSubAssy,'') ='' OR RoSubAssy LIKE '%' + @RoSubAssy + '%') AND
					(ISNULL(@Model,'') ='' OR Model LIKE '%' + @Model + '%') AND
					(ISNULL(@IsKitAssy,'') ='' OR IsKitAssy LIKE '%' + @IsKitAssy + '%'))
	)
				)
				INSERT INTO #Page (ItemMasterId, NumberOfItems)
				SELECT ItemMasterId, NumberOfItems FROM FilteredResult ORDER BY
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartNumber')  THEN PartNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartNumber')  THEN PartNumber END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='PartDescription')  THEN PartDescription END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='PartDescription')  THEN PartDescription END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Manufacturerdesc')  THEN Manufacturerdesc END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='Classificationdesc')  THEN Classificationdesc END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Classificationdesc')  THEN Classificationdesc END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ItemGroup')  THEN ItemGroup END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemGroup')  THEN ItemGroup END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='NationalStockNumber')  THEN NationalStockNumber END DESC, 			
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsSerialized')  THEN IsSerialized END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsSerialized')  THEN IsSerialized END DESC, 
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsTimeLife')  THEN IsTimeLife END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsTimeLife')  THEN IsTimeLife END DESC,	
			CASE WHEN (@SortOrder=1  AND @SortColumn='HasSubAssy')  THEN HasSubAssy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='HasSubAssy')  THEN HasSubAssy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='ItemType')  THEN ItemType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='ItemType')  THEN ItemType END DESC,
			--CASE WHEN (@SortOrder=1  AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END ASC,
			--CASE WHEN (@SortOrder=-1 AND @SortColumn='IsHazardousMaterial')  THEN IsHazardousMaterial END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='StockType')  THEN StockType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='StockType')  THEN StockType END DESC,			
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedBy')  THEN CreatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedBy')  THEN CreatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='CreatedDate')  THEN CreatedDates END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='CreatedDate')  THEN CreatedDates END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedBy')  THEN UpdatedBy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedBy')  THEN UpdatedBy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='UpdatedDate')  THEN UpdatedDate END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='UpdatedDate')  THEN UpdatedDate END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RankingsName')  THEN RankingsName END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RankingsName')  THEN RankingsName END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='workOrderType')  THEN workOrderType END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='workOrderType')  THEN workOrderType END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='RoSubAssy')  THEN RoSubAssy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RoSubAssy')  THEN RoSubAssy END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='Model')  THEN Model END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='Model')  THEN Model END DESC,
			CASE WHEN (@SortOrder=1  AND @SortColumn='IsKitAssy')  THEN IsKitAssy END ASC,
			CASE WHEN (@SortOrder=-1 AND @SortColumn='IsKitAssy')  THEN IsKitAssy END DESC
				OFFSET @RecordFrom ROWS
				FETCH NEXT @PageSize ROWS ONLY
				OPTION (RECOMPILE);
			END
			SET @Step = @Step + 1;
		END

		SELECT B.ItemMasterId,
		       B.PartNumber,
		       X.PartDescription,
		       B.Manufacturerdesc,
		       B.Classificationdesc,
		       B.ItemGroup,
		       B.NationalStockNumber,
		       B.IsSerialized,
		       B.IsTimeLife,
		       X.HasSubAssy,
		       X.RoSubAssy,
		       B.IsActive,
		       B.ItemType,
		       B.IsHazardousMaterial,
		       B.StockType,
		       B.CreatedDates,
		       B.CreatedDate,
		       B.UpdatedDate,
		       B.CreatedBy,
		       B.UpdatedBy,
		       B.IsDeleted,
		       X.RankingsName,
		       B.workOrderType,
		       B.IsNonStock,
		       B.IsAsset,
		       B.ItemTypeId,
		       B.Model,
		       B.IsKitAssy,
		       P.NumberOfItems
		FROM #Page P
		INNER JOIN #Base B ON B.ItemMasterId = P.ItemMasterId
		LEFT JOIN #Extra X ON X.ItemMasterId = P.ItemMasterId
		ORDER BY P.Seq;
		END TRY

	BEGIN CATCH	

		     DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'ProcItemMasterStockList'
			,@ProcedureParameters VARCHAR(3000) = 
			     '@Parameter1 = ''' + CAST(ISNULL(@PageNumber, '') as Varchar(100))
				 + ' @Parameter2 = ''' +  CAST(ISNULL(@PageSize, '') as Varchar(100))
				 + ' @Parameter3 = ''' + CAST(ISNULL(@SortColumn, '') as Varchar(100))
				 + ' @Parameter4 = ''' + CAST(ISNULL(@SortOrder, '') as Varchar(100))
				 + ' @Parameter5 = ''' + CAST(ISNULL(@GlobalFilter, '') as Varchar(100))
				 + ' @Parameter6 = ''' + CAST(ISNULL(@StatusId, '') as Varchar(100))
				 + ' @Parameter7 = ''' + CAST(ISNULL(@IsHazardousMaterial, '') as Varchar(100))
				 + ' @Parameter8 = ''' + CAST(ISNULL(@PartNumber , '') as Varchar(100))
				 + ' @Parameter9 = ''' + CAST(ISNULL(@PartDescription, '') as Varchar(100))
				 + ' @Parameter10 = ''' + CAST(ISNULL(@Manufacturerdesc , '') as Varchar(100))
				 + ' @Parameter11 = ''' + CAST(ISNULL(@Classificationdesc, '') as Varchar(100))
				 + ' @Parameter12 = ''' + CAST(ISNULL(@ItemGroup, '') as Varchar(100))
				 + ' @Parameter13 = ''' + CAST(ISNULL(@IsSerialized  , '') as Varchar(100))
				 + ' @Parameter14 = ''' + CAST(ISNULL(@IsTimeLife   , '') as Varchar(100))
				 + ' @Parameter14 = ''' + CAST(ISNULL(@HasSubAssy   , '') as Varchar(100))
				 + ' @Parameter15 = ''' + CAST(ISNULL(@StockType  , '') as Varchar(100))
				 + ' @Parameter16 = ''' + CAST(ISNULL(@ItemType  , '') as Varchar(100))
				 + ' @Parameter17 = ''' + CAST(ISNULL(@CreatedBy  , '') as Varchar(100))
				 + ' @Parameter18 = ''' + CAST(ISNULL(@CreatedDate   , '') as Varchar(100))
				 + ' @Parameter19 = ''' + CAST(ISNULL(@UpdatedBy   , '') as Varchar(100))
				 + ' @Parameter20 = ''' + CAST(ISNULL(@UpdatedDate    , '') as Varchar(100))
				 + ' @Parameter21 = ''' + CAST(ISNULL(@IsDeleted    , '') as Varchar(100))
				 + ' @Parameter22 = ''' + CAST(ISNULL(@MasterCompanyId   , '') as Varchar(100))
				,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);

	END CATCH
END