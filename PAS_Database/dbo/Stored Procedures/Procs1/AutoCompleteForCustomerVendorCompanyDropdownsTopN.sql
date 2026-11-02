/*************************************************************
 ** File:   [AutoCompleteForCustomerVendorCompanyDropdownsTopN]
 ** Description: Limited (Top N) version of [AutoCompleteForCustomerVendorCompanyDropdowns] - list of
 **              Customer, Vendor and LegalEntity (Company) for the Traceable To / Obtain From / Owner
 **              type autocompletes. The original SP returns EVERY active record (8k+ rows) when the
 **              search text is empty; this one returns only the first @Count matches.
 ** Date:    28/Oct/2026

 ** PARAMETERS:
 @Parameter       search text (contains match; records that START with the text are listed first)
 @Idlist          comma separated Ids (Customer / Vendor / LegalEntity) that must ALWAYS be returned
                  (already saved values), on top of the Top N
 @MasterCompanyId master company
 @Count           max number of records (excluding the @Idlist ones). Default 20. 0 or less = all records.

 ** RETURN VALUE: Value, Label, ModuleId, MasterCompanyId (same columns as the original SP)

 **************************************************************
  ** Change History
 **************************************************************
 ** PR   Date         Author		     Change Description
 ** --   --------     -------		 --------------------------------
    1    28/Oct/2026  RAJESH GAMI		[PN-18450] Created. Same source / filters as AutoCompleteForCustomerVendorCompanyDropdowns but
                                        only the Top @Count records are returned (Edit PO page: 20 on load, 100 while typing)
                                        so the page does not download and render 8k+ records.

 exec [AutoCompleteForCustomerVendorCompanyDropdownsTopN] '', '0', 1, 20
 exec [AutoCompleteForCustomerVendorCompanyDropdownsTopN] 'ap', '1287,1,2460', 1, 100
 exec [AutoCompleteForCustomerVendorCompanyDropdownsTopN] null, '0', 1, 0   -- all records

**************************************************************/
CREATE PROCEDURE [dbo].[AutoCompleteForCustomerVendorCompanyDropdownsTopN]
	@Parameter VARCHAR(50) = NULL,
	@Idlist VARCHAR(MAX) = '0',
	@MasterCompanyId INT,
	@Count INT = 20
AS BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
    BEGIN TRY
		DECLARE @CustomerModuleId INT = 0, @CompanyModuleId INT = 0, @VendorModuleId INT = 0
		DECLARE @Top INT = CASE WHEN ISNULL(@Count, 0) <= 0 THEN 2147483647 ELSE @Count END

		SELECT @CustomerModuleId = ModuleId FROM Module WITH(NOLOCK) WHERE ModuleName = 'Customer'
		SELECT @CompanyModuleId = ModuleId FROM Module WITH(NOLOCK) WHERE ModuleName = 'Company'
		SELECT @VendorModuleId = ModuleId FROM Module WITH(NOLOCK) WHERE ModuleName = 'Vendor'

		-- Ids that must always come back (saved values), whatever the Top N / search text is
		DECLARE @SelectedIds TABLE (Id BIGINT PRIMARY KEY)
		INSERT INTO @SelectedIds (Id)
		SELECT DISTINCT TRY_CAST(LTRIM(RTRIM(Item)) AS BIGINT)
		FROM DBO.SPLITSTRING(@Idlist, ',')
		WHERE TRY_CAST(LTRIM(RTRIM(Item)) AS BIGINT) IS NOT NULL

        CREATE TABLE #TempTable (
			Value BIGINT,
			Label VARCHAR(MAX),
			ModuleId INT,
			MasterCompanyId INT,
			IsSelected BIT,
			MatchRank INT
		)

		-- 1. Top N matching active records of each type (records starting with the search text first, then by name)
		INSERT INTO #TempTable (Value, Label, ModuleId, MasterCompanyId, IsSelected, MatchRank)
		SELECT TOP (@Top) CustomerId, Name, @CustomerModuleId, MasterCompanyId, 0,
			   CASE WHEN @Parameter IS NOT NULL AND Name LIKE @Parameter + '%' THEN 0 ELSE 1 END
		FROM dbo.Customer WITH(NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND (Name LIKE '%' + @Parameter + '%' OR @Parameter IS NULL)
		ORDER BY CASE WHEN @Parameter IS NOT NULL AND Name LIKE @Parameter + '%' THEN 0 ELSE 1 END, Name;

		INSERT INTO #TempTable (Value, Label, ModuleId, MasterCompanyId, IsSelected, MatchRank)
		SELECT TOP (@Top) VendorId, VendorName, @VendorModuleId, MasterCompanyId, 0,
			   CASE WHEN @Parameter IS NOT NULL AND VendorName LIKE @Parameter + '%' THEN 0 ELSE 1 END
		FROM dbo.Vendor WITH(NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND (VendorName LIKE '%' + @Parameter + '%' OR @Parameter IS NULL)
		ORDER BY CASE WHEN @Parameter IS NOT NULL AND VendorName LIKE @Parameter + '%' THEN 0 ELSE 1 END, VendorName;

		INSERT INTO #TempTable (Value, Label, ModuleId, MasterCompanyId, IsSelected, MatchRank)
		SELECT TOP (@Top) LegalEntityId, Name, @CompanyModuleId, MasterCompanyId, 0,
			   CASE WHEN @Parameter IS NOT NULL AND Name LIKE @Parameter + '%' THEN 0 ELSE 1 END
		FROM dbo.LegalEntity WITH(NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND IsActive = 1 AND ISNULL(IsDeleted, 0) = 0 AND (Name LIKE '%' + @Parameter + '%' OR @Parameter IS NULL)
		ORDER BY CASE WHEN @Parameter IS NOT NULL AND Name LIKE @Parameter + '%' THEN 0 ELSE 1 END, Name;

		-- 2. The Idlist records (always returned, same as the original SP: no active / deleted / search filter)
		INSERT INTO #TempTable (Value, Label, ModuleId, MasterCompanyId, IsSelected, MatchRank)
		SELECT CustomerId, Name, @CustomerModuleId, MasterCompanyId, 1, 0
		FROM dbo.Customer WITH(NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND CustomerId IN (SELECT Id FROM @SelectedIds);

		INSERT INTO #TempTable (Value, Label, ModuleId, MasterCompanyId, IsSelected, MatchRank)
		SELECT VendorId, VendorName, @VendorModuleId, MasterCompanyId, 1, 0
		FROM dbo.Vendor WITH(NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND VendorId IN (SELECT Id FROM @SelectedIds);

		INSERT INTO #TempTable (Value, Label, ModuleId, MasterCompanyId, IsSelected, MatchRank)
		SELECT LegalEntityId, Name, @CompanyModuleId, MasterCompanyId, 1, 0
		FROM dbo.LegalEntity WITH(NOLOCK)
		WHERE MasterCompanyId = @MasterCompanyId AND LegalEntityId IN (SELECT Id FROM @SelectedIds);

		-- 3. One row per Label + Module (as the original SP), keep only Top N of the non-Idlist rows, Idlist rows always kept
		WITH Ranked AS (
			SELECT *,
				   ROW_NUMBER() OVER (PARTITION BY Label, ModuleId ORDER BY IsSelected DESC, Value) AS rn
			FROM #TempTable
		), Numbered AS (
			SELECT *,
				   ROW_NUMBER() OVER (PARTITION BY IsSelected ORDER BY MatchRank, Label, ModuleId) AS seq
			FROM Ranked
			WHERE rn = 1
		)
		SELECT Value, Label, ModuleId, MasterCompanyId
		FROM Numbered
		WHERE IsSelected = 1 OR seq <= @Top
		ORDER BY MatchRank, Label, ModuleId;

        DROP TABLE #TempTable
    END TRY
    BEGIN CATCH
        DECLARE @ErrorLogID INT, @DatabaseName VARCHAR(100) =db_name(),
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            @AdhocComments VARCHAR(150) ='AutoCompleteForCustomerVendorCompanyDropdownsTopN', @ProcedureParameters VARCHAR(3000) =
			'@Parameter1 = '''+CAST(ISNULL(@Parameter, '') as varchar(100))+
			'@Parameter2 = '''+CAST(ISNULL(@Idlist, '') as varchar(100))+
			'@Parameter3 = '''+CAST(ISNULL(@MasterCompanyId, '') as varchar(100))+
			'@Parameter4 = '''+CAST(ISNULL(@Count, '') as varchar(100)),
			@ApplicationName VARCHAR(100) = 'PAS'
        -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
        EXEC spLogException @DatabaseName=@DatabaseName, @AdhocComments=@AdhocComments, @ProcedureParameters=@ProcedureParameters, @ApplicationName=@ApplicationName, @ErrorLogID=@ErrorLogID OUTPUT;
        RAISERROR('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
        RETURN (1);
    END CATCH
END
