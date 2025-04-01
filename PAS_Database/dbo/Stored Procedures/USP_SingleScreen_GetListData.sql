/*********************  
 ** File:   [USP_SingleScreen_GetListData]             
 ** Author:   Vishal Suthar  
 ** Description: This stored procedure is used to get single screen list data
 ** Purpose:           
 ** Date:   04/01/2024  
            
  ** Change History             
 **********************             
 ** PR   Date         Author  			Change Description              
 ** --   --------     -------			--------------------------------            
    1    04/01/2024   Vishal Suthar		Created
    2    24/02/2025   Ekta Chandegra	Convert date from UTC to Local
    3    05/03/2025   Bhargav Saliya	Cast the "ATAChapterCode" column as INT
    4    12/03/2025   Ekta Chandegra	Add Case for check EmployeeId and @CurrntEmpTimeZoneDesc having value
	5    17/03/2025   Ayushi Patel		Converted the date into utc (created , updated) , Added a case to get timeZone
	6	 01/04/2025   Devendra Shekh	Modified (For Task SS - Order By Description ASC)
**********************/
CREATE   PROCEDURE [dbo].[USP_SingleScreen_GetListData] 
	@PageNumber INT = NULL,
	@PageSize INT = NULL,
	@SortColumn VARCHAR(50) = NULL,
	@SortOrder INT = NULL,
	@GlobalFilter VARCHAR(50) = NULL,
	@xmlFilter XML,
	@PageName VARCHAR(100) = NULL,
	@MasterCompanyId INT = NULL,
	@EmployeeId BIGINT 

AS
BEGIN
  SET NOCOUNT ON;
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  BEGIN TRY
    DECLARE @RecordFrom AS INT
    DECLARE @GlobalFilterData AS VARCHAR(MAX)
    DECLARE @Query AS VARCHAR(MAX) = ''
    DECLARE @Orderby AS VARCHAR(MAX) = ''
    DECLARE @QueryFilterData AS VARCHAR(MAX)
    DECLARE @Erorr AS VARCHAR
    DECLARE @PrimaryColumn AS VARCHAR(100)
	DECLARE @SortAscScreen VARCHAR(200) = 'Task';

	-- New declaration for Employee's TimeZone description
	DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';

	-- Select the Employee's TimeZone description or fallback to LegalEntity's TimeZone
	SELECT 
		@CurrntEmpTimeZoneDesc = COALESCE(
			ETZ.[Description],  -- Prefer Employee's TimeZone description if available
			LTZ.[Description]   -- Fallback to LegalEntity's TimeZone description
		)
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

    IF (NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = @PageName))
    BEGIN
      SET @Erorr = @PageName + ' Screen table is not available';
      RAISERROR (@Erorr, 16, 1);
      RETURN
    END

    SET @RecordFrom = (@PageNumber - 1) * @PageSize;

    SELECT
      filterby.value('(FieldName/text())[1]', 'VARCHAR(100)') AS FieldName,
      filterby.value('(FieldValue/text())[1]', 'VARCHAR(100)') AS FieldValue INTO #tmpFilterData
    FROM @xmlFilter.nodes('/ArrayOfFilter/Filter') AS TEMPTABLE (filterby)

    SELECT @QueryFilterData = SUBSTRING(ResultData, 5, LEN(ResultData))
    FROM (SELECT (SELECT
        (CASE
          WHEN FieldName = 'status' THEN (CASE
              WHEN LOWER(FieldValue) = 'active' THEN ' And t.IsActive = 1'
              WHEN LOWER(FieldValue) = 'inactive' THEN ' And t.IsActive = 0'
              ELSE ''
            END)
          WHEN FieldName = 'isDeleted' THEN ' And ' + (CASE
              WHEN LOWER(FieldValue) = 'false' THEN 't.isDeleted = 0'
              ELSE 't.isDeleted = 1'
            END)
		  WHEN FieldName = 'createdDate' THEN ' And ' + 
			CASE 
				WHEN  @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != '' 
				THEN 'CAST(DBO.ConvertUTCtoLocal(t.CreatedDate, ''' + @CurrntEmpTimeZoneDesc + ''') AS DATE) = ''' + FieldValue + ''''
				ELSE 'CAST(t.CreatedDate AS DATE) = ''' + FieldValue + ''''
			END
		  WHEN FieldName = 'updatedDate' THEN ' And ' +
			CASE
				WHEN @EmployeeId != 0 AND @CurrntEmpTimeZoneDesc != ''  
				THEN 'CAST(DBO.ConvertUTCtoLocal(t.UpdatedDate, ''' + @CurrntEmpTimeZoneDesc + ''') AS DATE) = ''' + FieldValue + ''''
				ELSE 'CAST(t.UpdatedDate AS DATE) = ''' + FieldValue + ''''
			END
          WHEN LOWER(FieldName) = 'createdby' THEN ' And (ISNULL(createdby, '''') = '''' OR createdby LIKE ''%' + FieldValue + '%'')'
          WHEN LOWER(FieldName) = 'updatedby' THEN ' And (ISNULL(updatedby, '''') = '''' OR updatedby LIKE ''%' + FieldValue + '%'')'
          ELSE ' And (ISNULL(t.' + FieldName + ','''') ='''' OR t.' + FieldName + ' LIKE ''%' + FieldValue + '%'')'
        END)
      FROM #tmpFilterData
      FOR xml PATH (''))
      AS ResultData) AS temp

    DROP TABLE #tmpFilterData

    SELECT @GlobalFilterData = SUBSTRING(ResultData, 4, LEN(ResultData))
    FROM (SELECT (SELECT ' OR t.' + COLUMN_NAME + ' LIKE ''%' + @GlobalFilter + '%''' FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_NAME = @PageName FOR XML PATH ('')) AS ResultData) AS TempData

    IF (ISNULL(@GlobalFilterData, '') != '' AND ISNULL(@GlobalFilter, '') != '')
    BEGIN
      SET @QueryFilterData = @QueryFilterData + ' AND (' + @GlobalFilterData + ')'
    END

    DECLARE @SelectColumns AS VARCHAR(MAX)
    SELECT @SelectColumns = SUBSTRING(ResultData, 1, LEN(ResultData) - 1) FROM 
	(SELECT (SELECT 't.' + COLUMN_NAME + ',' FROM INFORMATION_SCHEMA.COLUMNS 
		WHERE TABLE_NAME = @PageName AND COLUMN_NAME NOT IN ('CreatedBy', 'UpdatedBy','CreatedDate','UpdatedDate') FOR XML PATH ('')) AS ResultData) AS TempData

    SET @Query = ';WITH Result AS(SELECT COUNT(1) OVER () AS NumberOfItems, ' + @SelectColumns + ', t.CreatedBy, t.UpdatedBy,(Cast(DBO.ConvertUTCtoLocal(t.CreatedDate,'''+@CurrntEmpTimeZoneDesc+''') as datetime)) CreatedDate,
					(Cast(DBO.ConvertUTCtoLocal(t.UpdatedDate, '''+@CurrntEmpTimeZoneDesc+''') as datetime)) UpdatedDate
					FROM [' + @PageName + '] t WITH (NOLOCK)
					WHERE t.MasterCompanyId = ' + CAST(@MasterCompanyId AS VARCHAR)
    + ' And ' + @QueryFilterData + ') 
	SELECT * FROM Result t '

    SET @Orderby = ' ORDER BY '
    IF (ISNULL(@SortColumn, '') = '')
    BEGIN
	
		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @PageName AND column_name = 'SequenceNo')
		BEGIN
			SET @Orderby += ' SequenceNo ASC '
		END
		ELSE IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @PageName AND column_name = 'Description' AND @PageName IN (SELECT value FROM string_split(@SortAscScreen, ',')))
		BEGIN
			SET @Orderby += ' Description ASC '
		END
		ELSE
			SET @Orderby += ' CreatedDate DESC '
    END
    ELSE
    BEGIN

		IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE table_name = @PageName AND @SortColumn = 'ATAChapterCode')
		BEGIN
			SET @Orderby = ' ORDER BY CASE WHEN TRY_CAST(t.' + QUOTENAME(@SortColumn) + ' AS INT) IS NOT NULL THEN 1 ELSE 2 END, TRY_CAST(t.' + QUOTENAME(@SortColumn) + ' AS INT) ' 
			+ CASE WHEN @SortOrder = 1 THEN 'ASC' ELSE 'DESC' END + ', t.' + QUOTENAME(@SortColumn) + ' ' + CASE WHEN @SortOrder = 1 THEN 'ASC' ELSE 'DESC' END;
		END
		ELSE
		BEGIN
		  SET @Orderby += CASE WHEN @SortOrder = 1 THEN 't.' + @SortColumn + ' ASC '
						   ELSE 't.' + @SortColumn + ' DESC '
						  END
		END
    END

    SET @Orderby += ' OFFSET ' + CAST(@RecordFrom AS varchar) + ' ROWS FETCH NEXT ' + CAST(@PageSize AS VARCHAR) + ' ROWS ONLY '

    PRINT (@Query + @Orderby)
    EXEC (@Query + @Orderby)
  END TRY
  BEGIN CATCH
    DECLARE @ErrorLogID int,
            @DatabaseName varchar(100) = DB_NAME()
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            ,@AdhocComments varchar(150) = 'USP_SingleScreen_GetListData',
            @ProcedureParameters varchar(max) = '@PageNumber = ''' + CAST(ISNULL(@PageNumber, '') AS VARCHAR(max))
            + '@PageSize = ''' + CAST(ISNULL(@PageSize, '') AS VARCHAR(100))
            + '@SortColumn = ''' + CAST(ISNULL(@SortColumn, '') AS VARCHAR(max))
            + '@SortOrder = ''' + CAST(ISNULL(@SortOrder, '') AS VARCHAR(max))
            + '@GlobalFilter = ''' + CAST(ISNULL(@GlobalFilter, '') AS VARCHAR(max))
            + '@xmlFilter = ''' + CAST(ISNULL(@xmlFilter, '') AS VARCHAR(max))
            + '@PageName = ''' + CAST(ISNULL(@PageName, '') AS VARCHAR(max))
            + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(max)),
            @ApplicationName varchar(100) = 'PAS'
    -----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
    EXEC spLogException @DatabaseName = @DatabaseName,
                        @AdhocComments = @AdhocComments,
                        @ProcedureParameters = @ProcedureParameters,
                        @ApplicationName = @ApplicationName,
                        @ErrorLogID = @ErrorLogID OUTPUT;
    RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

  END CATCH
END