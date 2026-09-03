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
	4    28/01/2025     Ayushi Patel         converted the date into utc (created , updated) , Added a case to get timeZone
	5	 14/02/2025		Ayushi Patel		 Resolve sorting related issue (createdDates)
	6    06-03-2025     Shrey Chandegara     Modified due to add view in Accouting Integration List's PendingSync(Add @IsUpdated parameter)
	7    01-Aug-2025    Bhargav saliya       Modified [HasSubAssy] field Conditon 
	8	 07-Aug-2025	Ayushi Patel		 added condition for IsOEM
	9	 21-Aug-2025	Bhargav saliya		 added Ranking
	10   04-Sep-2025    Sahdev Saliya        Added WorkOrderType
	11   09-Sep-2025    Sahdev Saliya        Added Filter For RankingsName And WorkOrderType
	12   12-Nov-2025    Divyesh Kathiriya    Update HasSubAssy only return 'WoSubAssy' value due to column name change.
	13   14-Nov-2025    Divyesh Kathiriya     Get RoSubAssy.
	14   29-Jun-2026    Rajesh Gami			 Merging the NonStock Inventory to Inventory [PN-17008]
	15    07-07-2026   Bhargav Saliya   Added @IntegrationTypeId [PN-16810]
	16   08-03-2026    Rajesh Gami      Performance pass: removed per-row scalar UDF call
										 (DBO.ConvertUTCtoLocal), removed unneeded SELECT DISTINCT,
										 converted HasSubAssy/RoSubAssy COUNT(...)>0 checks to
										 EXISTS(...), and removed #TempResult / separate COUNT
										 pass (now COUNT(*) OVER()). See
										 ProcItemMasterStockList_Performance_Recommendations.sql
										 for the full before/after review.
	17   02-Sep-2026    Bhargav Saliya       [PN-17849] Part Number filter: normalize dashes(-)/slashes("\","/")/underscore(_)

**********************/
CREATE     PROCEDURE [dbo].[ProcItemMasterStockList]
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
@IntegrationTypeId BIGINT = null,
@ItemTypeStatusId varchar(50) = NULL
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
		SET @ItemTypeStatusId = CASE WHEN @ItemTypeStatusId > 0 THEN @ItemTypeStatusId ELSE NULL END
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
		;WITH CTE_IntegrationPortal AS (
			SELECT
				iM.ItemMasterId,
				STRING_AGG(CAST(R.[Description] AS NVARCHAR(MAX)), ',') AS Ranking,
				STRING_AGG(mp.RankingId, ',') AS RankingIds
			FROM dbo.ItemMaster iM WITH(NOLOCK)
			INNER JOIN dbo.ItemMasterRanking mp WITH(NOLOCK) ON iM.ItemMasterId = mp.ItemMasterId
			INNER JOIN dbo.Ranking R WITH(NOLOCK) ON mp.RankingId = R.RankingId
			WHERE mp.RankingId IS NOT NULL GROUP BY iM.ItemMasterId
		),
		
		 Result AS(
				-- PERF FIX: removed SELECT DISTINCT - CTE_IntegrationPortal is already
				-- GROUP BY ItemMasterId (one row per key) and is LEFT JOINed 1:1 on that same
				-- key; nothing else in this SELECT can fan a row out, since HasSubAssy/RoSubAssy
				-- are scalar subqueries, not joins. im.ItemMasterId (the driving PK) already
				-- guarantees uniqueness, so DISTINCT was just an extra sort/hash over every
				-- computed column for no benefit.
				SELECT im.ItemMasterId,
				       im.PartNumber,
					   im.PartDescription,
					   (ISNULL(im.ManufacturerName,'')) 'Manufacturerdesc',
					   im.ItemClassificationName 'Classificationdesc',
					   (ISNULL(im.ItemGroup,'')) 'ItemGroup',
					   im.NationalStockNumber,
					   CASE WHEN im.IsSerialized = 1 THEN 'Yes' ELSE 'No' END AS IsSerialized,
					   CASE WHEN im.IsTimeLife = 1 THEN 'Yes' ELSE 'No' END AS IsTimeLife,
					   --CAST(im.IsSerialized AS varchar) 'IsSerialized',
					   --CAST(im.IsTimeLife AS varchar) 'IsTimeLife',
					   -- PERF FIX: COUNT(...) > 0 -> EXISTS(...). Same result, but SQL Server can
					   -- stop at the first matching row instead of counting every match, and this
					   -- now has a supporting index on (ItemMasterId, PopulateWoMaterialList).
					   CASE WHEN EXISTS (SELECT 1 FROM [DBO].[Assemply] AP WITH (NOLOCK) WHERE AP.ItemMasterId = im.ItemMasterId AND AP.PopulateWoMaterialList = 1) THEN 'Yes' ELSE 'No' END AS HasSubAssy,
					   CASE WHEN EXISTS (SELECT 1 FROM [DBO].[RepairOrderAssembly] RAP WITH (NOLOCK) WHERE RAP.ItemMasterId = im.ItemMasterId) THEN 'Yes' ELSE 'No' END AS RoSubAssy,
					   im.IsActive,
					   ItemType = CASE WHEN im.ItemTypeId = 1 THEN 'Stock' ELSE 'NonStock' END,
					   CAST(im.IsHazardousMaterial AS varchar) 'IsHazardousMaterial',
					   StockType = (CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER'
										 WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA'
					                     WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER'
										 WHEN im.IsOEM = 1 THEN 'OEM'
										 ELSE ''
									END),
					   im.CreatedDate CreatedDates,
                       --im.UpdatedDate,
					   -- PERF FIX: inline DATEADD using the offset resolved once above, instead of
					   -- calling DBO.ConvertUTCtoLocal(...) per row (see note near @BaseUtcOffsetSec).
					   CAST(DATEADD(SECOND, @BaseUtcOffsetSec, im.CreatedDate) AS Date) AS CreatedDate,
					   CAST(DATEADD(SECOND, @BaseUtcOffsetSec, im.UpdatedDate) AS Date) AS UpdatedDate,
					   im.CreatedBy,
                       im.UpdatedBy,
					   im.IsDeleted,
					   itp.Ranking as RankingsName,
					   CASE WHEN im.WorkOrderFormTypeId = 1 THEN 'Dynamic' WHEN im.WorkOrderFormTypeId = 2 THEN 'Static' ELSE 'At WO creation' END AS workOrderType,
					    ISNULL(IM.IsNonStock,0)IsNonStock,
						im.ItemTypeId
			   FROM dbo.ItemMaster im WITH (NOLOCK)
			   left join CTE_IntegrationPortal itp WITH(NOLOCK) ON iM.ItemMasterId = itp.ItemMasterId
		 	  WHERE ((im.IsDeleted=@IsDeleted) AND (@IsActive IS NULL OR im.IsActive=@IsActive) AND (@IsHazardousMaterial IS NULL OR im.IsHazardousMaterial=@IsHazardousMaterial))
					AND im.MasterCompanyId=@MasterCompanyId
					 AND (@ItemTypeStatusId IS NULL OR im.ItemTypeId = @ItemTypeStatusId)
					AND (ISNULL(@IsUpdated,0) <> 1 OR ISNULL(im.isUpdated,0) = ISNULL(@IsUpdated,0))
					AND (@IntegrationTypeId IS NULL OR im.IntegrationTypeId = @IntegrationTypeId)
			),
			-- PERF FIX: filters now run directly against Result (no #TempResult heap table), and
			-- COUNT(*) OVER() supplies NumberOfItems in the same pass that gets sorted/paged below
			-- - this replaces the old #TempResult + separate "SELECT @Count = COUNT(...)" scan
			-- with a single pass.
			FilteredResult AS (
			SELECT *, COUNT(*) OVER() AS NumberOfItems
			FROM Result
			 WHERE ((@GlobalFilter <>'' AND ((PartNumber LIKE '%' +@GlobalFilter+'%' OR dbo.fn_NormalizePartNumber(PartNumber) LIKE '%' +dbo.fn_NormalizePartNumber(@GlobalFilter)+'%') OR
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
					(RoSubAssy LIKE '%' +@GlobalFilter+'%')))	
					OR   
					(@GlobalFilter='' AND (ISNULL(@PartNumber,'') ='' OR PartNumber LIKE '%' + @PartNumber+'%' OR dbo.fn_NormalizePartNumber(PartNumber) LIKE '%' +dbo.fn_NormalizePartNumber(@PartNumber)+'%') AND
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
					(ISNULL(@RoSubAssy,'') ='' OR RoSubAssy LIKE '%' + @RoSubAssy + '%'))
	)
			)

			SELECT * FROM FilteredResult ORDER BY
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
			CASE WHEN (@SortOrder=-1 AND @SortColumn='RoSubAssy')  THEN RoSubAssy END DESC
			OFFSET @RecordFrom ROWS 
			FETCH NEXT @PageSize ROWS ONLY
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