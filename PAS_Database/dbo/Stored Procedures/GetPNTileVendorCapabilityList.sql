/*************************************************************
** File:   [GetPNTileVendorCapabilityList]
** Author:   Bhargav Saliya
** Description: Parts Inquiry (Trading Page) tile - vendors whose Vendor Capabilities
**              match the searched part (ItemMasterId).
** Purpose:
** Date:   19-Nov-2026
**************************************************************
** Change History
**************************************************************
** PR   Date         Author				Change Description
** --   --------     -------			--------------------------------
 1   19-Nov-2026	Bhargav Saliya		[PN-18609] Created
**************************************************************/
/*
EXEC dbo.GetPNTileVendorCapabilityList @PageNumber=1,@PageSize=10,@SortColumn=N'VendorRanking',@SortOrder=1,@GlobalFilter=N'',@ItemMasterId=7,@MasterCompanyId=1
*/
CREATE   PROCEDURE [dbo].[GetPNTileVendorCapabilityList]
	@PageNumber int = 1,
	@PageSize int = 10,
	@SortColumn varchar(50) = NULL,
	@SortOrder int = NULL,
	@GlobalFilter varchar(50) = NULL,
	@IsDeleted bit = NULL,
	@MasterCompanyId bigint = NULL,
	@ItemMasterId bigint = 0,
	@EmployeeId bigint = 0,
	@VendorName varchar(100) = NULL,
	@VendorCode varchar(100) = NULL,
	@CapabilityType varchar(100) = NULL,
	@CapabilityTypeDescription varchar(256) = NULL,
	@VendorRanking varchar(20) = NULL,
	@IsPMA varchar(10) = NULL,
	@IsDER varchar(10) = NULL,
	@TAT varchar(20) = NULL,
	@Cost varchar(50) = NULL,
	@Currency varchar(50) = NULL,
	@AircraftEngine varchar(256) = NULL,
	@Memo varchar(250) = NULL,
	@CostDate datetime = NULL,
	@VerifiedDate datetime = NULL
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		DECLARE @RecordFrom int;
		DECLARE @Count int;

		SET @PageNumber = ISNULL(NULLIF(@PageNumber, 0), 1);
		SET @PageSize = ISNULL(NULLIF(@PageSize, 0), 10);
		SET @RecordFrom = (@PageNumber - 1) * @PageSize;
		SET @IsDeleted = ISNULL(@IsDeleted, 0);
		SET @GlobalFilter = ISNULL(@GlobalFilter, '');
		SET @SortColumn = UPPER(ISNULL(NULLIF(@SortColumn, ''), 'VENDORRANKING'));
		IF (@SortColumn = 'CREATEDDATE') -- API default when the grid has no sort
		BEGIN
			SET @SortColumn = 'VENDORRANKING';
			SET @SortOrder = 1;
		END
		SET @SortOrder = ISNULL(@SortOrder, 1);

		SELECT vc.VendorCapabilityId,
			   vc.VendorId,
			   v.VendorName,
			   v.VendorCode,
			   vc.ItemMasterId,
			   im.PartNumber,
			   im.PartDescription,
			   vc.CapabilityTypeId,
			   ISNULL(ct.CapabilityTypeDesc, vc.CapabilityTypeName) AS CapabilityType,
			   vc.CapabilityTypeDescription,
			   vc.VendorRanking,
			   CASE WHEN ISNULL(vc.IsPMA, 0) = 1 THEN 'Yes' ELSE 'No' END AS IsPMA,
			   CASE WHEN ISNULL(vc.IsDER, 0) = 1 THEN 'Yes' ELSE 'No' END AS IsDER,
			   vc.TAT,
			   vc.Cost,
			   vc.CostDate,
			   vc.CurrencyId,
			   ISNULL(cur.Code, vc.Currency) AS Currency,
			   vc.AircraftEngine,
			   vc.VerifiedDate,
			   vc.Memo,
			   vc.CreatedDate,
			   vc.UpdatedDate
		INTO #TempResult
		FROM [dbo].[VendorCapability] vc WITH (NOLOCK)
		INNER JOIN [dbo].[Vendor] v WITH (NOLOCK) ON v.VendorId = vc.VendorId
		INNER JOIN [dbo].[ItemMaster] im WITH (NOLOCK) ON im.ItemMasterId = vc.ItemMasterId
		LEFT JOIN [dbo].[CapabilityType] ct WITH (NOLOCK) ON ct.CapabilityTypeId = vc.CapabilityTypeId
		LEFT JOIN [dbo].[Currency] cur WITH (NOLOCK) ON cur.CurrencyId = vc.CurrencyId
		WHERE vc.ItemMasterId = @ItemMasterId
		  AND vc.MasterCompanyId = @MasterCompanyId
		  AND vc.IsDeleted = @IsDeleted
		  AND vc.IsActive = 1
		  AND ISNULL(v.IsDeleted, 0) = 0
		  AND ISNULL(v.IsActive, 1) = 1;

		-- CASE so that NULL column values (UNKNOWN) count as "no match" and are removed
		DELETE FROM #TempResult
		WHERE 0 = CASE WHEN (
			(@GlobalFilter <> '' AND (
				VendorName LIKE '%' + @GlobalFilter + '%' OR
				VendorCode LIKE '%' + @GlobalFilter + '%' OR
				CapabilityType LIKE '%' + @GlobalFilter + '%' OR
				CapabilityTypeDescription LIKE '%' + @GlobalFilter + '%' OR
				CAST(VendorRanking AS varchar(20)) LIKE '%' + @GlobalFilter + '%' OR
				CAST(TAT AS varchar(20)) LIKE '%' + @GlobalFilter + '%' OR
				CAST(Cost AS varchar(50)) LIKE '%' + @GlobalFilter + '%' OR
				Currency LIKE '%' + @GlobalFilter + '%' OR
				AircraftEngine LIKE '%' + @GlobalFilter + '%' OR
				Memo LIKE '%' + @GlobalFilter + '%'))
			OR
			(@GlobalFilter = '' AND
				(ISNULL(@VendorName, '') = '' OR VendorName LIKE '%' + @VendorName + '%') AND
				(ISNULL(@VendorCode, '') = '' OR VendorCode LIKE '%' + @VendorCode + '%') AND
				(ISNULL(@CapabilityType, '') = '' OR CapabilityType LIKE '%' + @CapabilityType + '%') AND
				(ISNULL(@CapabilityTypeDescription, '') = '' OR CapabilityTypeDescription LIKE '%' + @CapabilityTypeDescription + '%') AND
				(ISNULL(@VendorRanking, '') = '' OR CAST(VendorRanking AS varchar(20)) LIKE '%' + @VendorRanking + '%') AND
				(ISNULL(@IsPMA, '') = '' OR IsPMA LIKE '%' + @IsPMA + '%') AND
				(ISNULL(@IsDER, '') = '' OR IsDER LIKE '%' + @IsDER + '%') AND
				(ISNULL(@TAT, '') = '' OR CAST(TAT AS varchar(20)) LIKE '%' + @TAT + '%') AND
				(ISNULL(@Cost, '') = '' OR CAST(Cost AS varchar(50)) LIKE '%' + @Cost + '%') AND
				(ISNULL(@Currency, '') = '' OR Currency LIKE '%' + @Currency + '%') AND
				(ISNULL(@AircraftEngine, '') = '' OR AircraftEngine LIKE '%' + @AircraftEngine + '%') AND
				(ISNULL(@Memo, '') = '' OR Memo LIKE '%' + @Memo + '%') AND
				(@CostDate IS NULL OR CAST(CostDate AS date) = CAST(@CostDate AS date)) AND
				(@VerifiedDate IS NULL OR CAST(VerifiedDate AS date) = CAST(@VerifiedDate AS date)))
		) THEN 1 ELSE 0 END;

		SELECT @Count = COUNT(1) FROM #TempResult;

		SELECT *, @Count AS NumberOfItems
		FROM #TempResult
		ORDER BY
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'VENDORNAME') THEN VendorName END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VENDORNAME') THEN VendorName END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'VENDORCODE') THEN VendorCode END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VENDORCODE') THEN VendorCode END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CAPABILITYTYPE') THEN CapabilityType END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CAPABILITYTYPE') THEN CapabilityType END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CAPABILITYTYPEDESCRIPTION') THEN CapabilityTypeDescription END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CAPABILITYTYPEDESCRIPTION') THEN CapabilityTypeDescription END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'VENDORRANKING') THEN VendorRanking END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VENDORRANKING') THEN VendorRanking END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'ISPMA') THEN IsPMA END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ISPMA') THEN IsPMA END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'ISDER') THEN IsDER END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'ISDER') THEN IsDER END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'TAT') THEN TAT END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'TAT') THEN TAT END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'COST') THEN Cost END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'COST') THEN Cost END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'COSTDATE') THEN CostDate END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'COSTDATE') THEN CostDate END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'CURRENCY') THEN Currency END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'CURRENCY') THEN Currency END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'AIRCRAFTENGINE') THEN AircraftEngine END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'AIRCRAFTENGINE') THEN AircraftEngine END DESC,
			CASE WHEN (@SortOrder = 1  AND @SortColumn = 'VERIFIEDDATE') THEN VerifiedDate END ASC,
			CASE WHEN (@SortOrder = -1 AND @SortColumn = 'VERIFIEDDATE') THEN VerifiedDate END DESC,
			VendorRanking ASC, VendorName ASC
		OFFSET @RecordFrom ROWS
		FETCH NEXT @PageSize ROWS ONLY;
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			,@AdhocComments VARCHAR(150) = 'GetPNTileVendorCapabilityList'
			,@ProcedureParameters VARCHAR(3000) =
				 '@PageNumber = ''' + CAST(ISNULL(@PageNumber, '') AS varchar(100))
				 + ''', @PageSize = ''' + CAST(ISNULL(@PageSize, '') AS varchar(100))
				 + ''', @SortColumn = ''' + CAST(ISNULL(@SortColumn, '') AS varchar(100))
				 + ''', @SortOrder = ''' + CAST(ISNULL(@SortOrder, '') AS varchar(100))
				 + ''', @GlobalFilter = ''' + CAST(ISNULL(@GlobalFilter, '') AS varchar(100))
				 + ''', @ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100))
				 + ''', @MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) + ''''
			,@ApplicationName VARCHAR(100) = 'PAS'
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;
		RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d',16,1,@ErrorLogID)
		RETURN (1);
	END CATCH
END
