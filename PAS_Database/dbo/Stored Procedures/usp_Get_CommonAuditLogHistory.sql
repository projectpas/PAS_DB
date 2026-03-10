/*********************             
 ** File:   [dbo].[usp_Get_CommonAuditLogHistory]        
 ** Author:   HEMANT SALIYA    
 ** Description: Get Data for Common Audit Report   
 ** Purpose:           
 ** Date:   07-NOV-2025        
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **********************             
  ** Change History             
 **********************             
 ** S NO		Date			Author				Change Description              
 ** --		--------		-------------		--------------------------------            
    1		07-NOV-2025		HEMANT SALIYA			Created  
    2       11-NOV-2025     AYUSHI PATEL            Mapped ModuleId to Module 
    3       12-NOV-2025     AYUSHI PATEL            Removed TableName, PKJson, ChangedBy, Actions from output; added UpdatedDate fallback to ChangedAt; excluded columns via IgnoreColumn.
    4       20-NOV-2025     AYUSHI PATEL            Converted UpdatedDate/CreatedDate to employee timezone.
    5       16-FEB-2026     DIVYESH KATHIRIYA       Set Table Name for SalesOrderQuote.
    6       25-FEB-2026     DIVYESH KATHIRIYA       Set New HistoryModule Table and Remove Table Name for SalesOrderQuote.
    7       27-FEB-2026     DIVYESH KATHIRIYA       Set @SubModuleId, @SubPK_Key, @SubPK_Value.
    8       10-MAR-2026     NAKUL CHANDIGRA         Add a condition of IgnoreColumn In '@sql = N';WITH S AS' to prevent Getting dublicate value

EXEC usp_Get_CommonAuditLogHistory @ModuleId=68, @PK_Key=N'CustomerContactId', @PK_Value=6678, @EmployeeId=236, @SubModuleId=69, @SubPK_Key=N'ContactId', @SubPK_Value=14040
**********************/ 

CREATE PROC [dbo].[usp_Get_CommonAuditLogHistory]
    @ModuleId       BIGINT        = NULL,       -- e.g. '1 => Customer' / 'Vendor' (maps to TableName)
    @PK_Key         nvarchar(128) = NULL,       -- e.g. 'CustomerContactId'
    @PK_Value       nvarchar(128) = NULL,       -- e.g. '6678' (compared as NVARCHAR)
    @StartAt        datetime2(3)  = NULL,       -- inclusive
    @EndAt          datetime2(3)  = NULL,       -- exclusive
    @UseOld         bit           = 0,          -- 0 = pivot NewValue, 1 = pivot OldValue
    @SortDir        nvarchar(4)   = N'DESC',    -- ASC | DESC (by ChangedAt)
    @EmployeeId     BIGINT        = NULL,
    @SubModuleId    BIGINT        = NULL,       -- e.g. '1 => Customer' / 'Vendor' (maps to TableName)
    @SubPK_Key      nvarchar(128) = NULL,       -- e.g. 'ContactId'
    @SubPK_Value    nvarchar(128) = NULL        -- e.g. '14040'
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    BEGIN TRY
    
        DECLARE @sql nvarchar(MAX);
        DECLARE @cols nvarchar(MAX);
        DECLARE @CurrntEmpTimeZoneDesc VARCHAR(100) = '';
        DECLARE @Module VARCHAR(100);
        DECLARE @SubModule VARCHAR(100) = NULL;
        DECLARE @CustomerContactModule AS INT;    


        -- Validate sort dir
        IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';
    
        SET @Module = (SELECT [HistoryModuleName] FROM [dbo].[HistoryModule] WITH (NOLOCK) WHERE [HistoryModuleId] = @ModuleId);
        SET @SubModule = (SELECT [HistoryModuleName] FROM [dbo].[HistoryModule] WITH (NOLOCK) WHERE [HistoryModuleId] = @SubModuleId);

        SET @CustomerContactModule = (SELECT [HistoryModuleId] FROM [dbo].[HistoryModule] WITH(NOLOCK) WHERE [HistoryModuleName] = 'CustomerContact');
        
       
        SELECT @CurrntEmpTimeZoneDesc = COALESCE(ETZ.[Description], LTZ.[Description])
        FROM dbo.Employee E WITH (NOLOCK)
        LEFT JOIN dbo.TimeZone ETZ WITH (NOLOCK) ON E.TimeZoneId = ETZ.TimeZoneId
        LEFT JOIN dbo.LegalEntity LE WITH (NOLOCK) ON E.LegalEntityId = LE.LegalEntityId
        LEFT JOIN dbo.TimeZone LTZ WITH (NOLOCK) ON LE.TimeZoneId = LTZ.TimeZoneId
        WHERE E.EmployeeId = @EmployeeId;

---------------------------------------------------------------------------------
    -- Build dynamic column list from ColumnName in the filtered scope
    -- (ensures only relevant fields appear as pivoted columns)
-----------------------------------------------------------------------------------   
        
        IF (@ModuleId = @CustomerContactModule)
        BEGIN 
    
            SELECT @cols =
                STRING_AGG(QUOTENAME(ColumnName), ',')
            FROM (
                SELECT DISTINCT ColumnName
                FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                WHERE (
                        -- MAIN MODULE FILTER
                        (@Module IS NULL OR TableName = @Module
                            AND (
                                    @PK_Key IS NULL OR @PK_Value IS NULL
                                    OR TRY_CONVERT(nvarchar(128),
                                        JSON_VALUE(PKJson, CONCAT('$.', @PK_Key))) = @PK_Value
                                )
                        )
                        OR
                        -- SUB-MODULE FILTER (CustomerContact → Contact)
                        (@Module IS NULL OR @Module = 'CustomerContact'
                            AND TableName = @SubModule
                            AND (
                                    @SubPK_Key   IS NOT NULL
                                AND @SubPK_Value IS NOT NULL
                                AND TRY_CONVERT(nvarchar(128),
                                    JSON_VALUE(PKJson, CONCAT('$.', @SubPK_Key))) = @SubPK_Value
                            )                
                        )
                    )
                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
                  AND ColumnName IS NOT NULL
                  AND ColumnName <> ''
                  AND LEN(ColumnName) <= 128         -- QUOTENAME limit
                  AND NOT EXISTS (            
                  SELECT 1
                  FROM dbo.IgnoreColumn ic WITH (NOLOCK)
                  WHERE ic.TableName = @Module
                    AND ic.ColumnName = AL.ColumnName
            )
            ) AS c;
        END
        ELSE
        BEGIN
            SELECT @cols =
                STRING_AGG(QUOTENAME(ColumnName), ',')
            FROM (
                SELECT DISTINCT ColumnName
                FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                WHERE (@Module IS NULL OR TableName = @Module)
                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
                  AND (
                        @PK_Key IS NULL OR @PK_Value IS NULL
                        OR TRY_CONVERT(nvarchar(128), JSON_VALUE(PKJson, CONCAT('$.', @PK_Key))) = @PK_Value
                      )
                  AND ColumnName IS NOT NULL
                  AND ColumnName <> ''
                  AND LEN(ColumnName) <= 128         -- QUOTENAME limit
                  AND NOT EXISTS (            
                  SELECT 1
                  FROM dbo.IgnoreColumn ic WITH (NOLOCK)
                  WHERE ic.TableName = @Module
                    AND ic.ColumnName = AL.ColumnName
            )
            ) AS c;
        END


        IF CHARINDEX('[UpdatedDate]', @cols) = 0
        SET @cols = @cols + ',[UpdatedDate]';

        IF CHARINDEX('[CreatedDate]', @cols) = 0
        SET @cols = @cols + ',[CreatedDate]';

        -- If nothing to pivot, return an empty-shaped set
        IF (@cols IS NULL OR @cols = '')
        BEGIN
            SELECT TOP (0)
                @Module AS TableName,
                @PK_Key AS PKJson,
                *
                FROM STRING_SPLIT(@cols,',')
            RETURN;
        END

        DECLARE @cols_out nvarchar(MAX);
        SELECT @cols_out =
            STRING_AGG(s.value, ',')
        FROM STRING_SPLIT(@cols, ',') AS s
        WHERE s.value NOT IN ('[UpdatedDate]', '[CreatedDate]');


        DECLARE @valExpr nvarchar(20) =
            CASE WHEN @UseOld = 1 THEN N'OldValue' ELSE N'NewValue' END;

    ----------------------------------------------------------------
    -- Dynamic pivot:
    --  - Deduplicate multiple rows for the same column at the same event
    --  - Pivot columns = each distinct ColumnName
    --  - Include a compact Actions string (e.g., 'I', 'U', 'D' or combination)
    ----------------------------------------------------------------
        IF (@ModuleId = @CustomerContactModule)
        BEGIN 
            SET @sql =N';WITH S AS
                        (
                            SELECT
                                AuditId,
                                TableName,
                                PKJson,
                                ColumnName,
                                [Action],
                                OldValue,
                                NewValue,
                                ChangedBy,
                                ChangedAt
                            FROM [dbo].[AuditLog] WITH (NOLOCK)
                            WHERE 1=1              
                              AND (
                                    -- MAIN MODULE FILTER
                                    (@Module  IS NULL OR TableName = @Module
                                        AND (
                                                @PK_Key IS NULL OR @PK_Value IS NULL
                                                OR TRY_CONVERT(nvarchar(128),
                                                   JSON_VALUE(PKJson, CONCAT(''$.'' , @PK_Key))) = @PK_Value
                                            )
                                    )

                                    OR

                                    -- SUB-MODULE FILTER (CustomerContact → Contact)
                                    (@Module  IS NULL OR @Module = ''CustomerContact''
                                        AND TableName = ''' + ISNULL(@SubModule,'') + '''
                                        AND (
                                                @SubPK_Key   IS NOT NULL
                                            AND @SubPK_Value IS NOT NULL
                                            AND TRY_CONVERT(nvarchar(128),
                                                JSON_VALUE(PKJson, CONCAT(''$.'' , @SubPK_Key))) = @SubPK_Value
                                        )
                                    )
                                 )
                                  AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                                  AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
              
                        ),'
        END
        ELSE
        BEGIN
            SET @sql = N';WITH S AS
                        (
                            SELECT
                                AuditId,
                                TableName,
                                PKJson,
                                ColumnName,
                                [Action],
                                OldValue,
                                NewValue,
                                ChangedBy,
                                ChangedAt
                            FROM [dbo].[AuditLog] AL WITH (NOLOCK)
                            WHERE 1=1
                              AND (@Module  IS NULL OR TableName = @Module)
                              AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
                              AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
                              AND (
                                    @PK_Key IS NULL OR @PK_Value IS NULL
                                    OR TRY_CONVERT(nvarchar(128), JSON_VALUE(PKJson, CONCAT(''$.'' , @PK_Key))) = @PK_Value
                                  )
                              AND NOT EXISTS ( SELECT 1 FROM dbo.IgnoreColumn ic WITH (NOLOCK) WHERE ic.TableName = @Module AND ic.ColumnName = AL.ColumnName )
                        ),'
        END   

        SET @sql += N'Dedup AS
            (
                -- If multiple rows for same (Table,PKJson,ChangedAt,ColumnName), take latest by AuditId
                SELECT
                    TableName, PKJson, ChangedAt, ChangedBy, ColumnName, [Action],
                    CONVERT(nvarchar(max), ' + @valExpr + N') AS ValToPivot,
                    ROW_NUMBER() OVER (
                        PARTITION BY TableName, PKJson, ChangedAt, ColumnName, [Action]
                        ORDER BY AuditId DESC
                    ) AS rn
                FROM S
            ),
            FinalSource AS
            (
                SELECT TableName, PKJson, ChangedAt, ChangedBy, ColumnName, [Action], ValToPivot
                FROM Dedup
                WHERE rn = 1
            ),
            Agg AS
            (
                SELECT
                    TableName,
                    PKJson,
                    ChangedAt,
                    MIN(ChangedBy) AS AnyChangedBy,               -- usually 1 user per event
                    [Action] AS Actions
                    --STRING_AGG(DISTINCT Action, '''') AS Actions   -- e.g. I/U/D compressed
                FROM S
                GROUP BY TableName, PKJson, ChangedAt, [Action]
            )
            SELECT
                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                         THEN COALESCE(p.[UpdatedDate], p.ChangedAt)
                    WHEN TRY_CAST(p.[UpdatedDate] AS datetime2(3)) IS NULL
                         OR TRY_CAST(p.[UpdatedDate] AS date) = ''0001-01-01''
                         THEN CAST(dbo.ConvertUTCtoLocal(p.ChangedAt, @CurrntEmpTimeZoneDesc) AS datetime2(3))
                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[UpdatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS UpdatedDate,

                CASE 
                    WHEN @CurrntEmpTimeZoneDesc IS NULL OR LEN(@CurrntEmpTimeZoneDesc) = 0
                         THEN p.[CreatedDate]
                    WHEN TRY_CAST(p.[CreatedDate] AS datetime2(3)) IS NULL
                         OR TRY_CAST(p.[CreatedDate] AS date) = ''0001-01-01''
                         THEN NULL
                    ELSE CAST(dbo.ConvertUTCtoLocal(TRY_CAST(p.[CreatedDate] AS datetime2(3)), @CurrntEmpTimeZoneDesc) AS datetime2(3))
                END AS CreatedDate'
                + CASE WHEN ISNULL(@cols_out, N'') <> N'' THEN
                        N', ' + REPLACE(@cols_out, '],[', '], p.[')
                    ELSE N''
                  END
                + N'
            FROM
            (
                SELECT TableName, PKJson, ChangedAt, ChangedBy, ColumnName, ValToPivot
                FROM FinalSource
            ) AS src
            PIVOT
            (
                MAX(ValToPivot) FOR ColumnName IN (' + @cols + N')
            ) AS p
            JOIN Agg a
              ON a.TableName = p.TableName
             AND a.PKJson    = p.PKJson
             AND a.ChangedAt = p.ChangedAt
            ORDER BY p.ChangedAt ' + @SortDir + N', p.TableName, p.PKJson;';

    --EXEC sp_executesql
    --    @sql,
    --    N'@Module sysname, @StartAt datetime2(3), @EndAt datetime2(3), @PK_Key nvarchar(128), @PK_Value nvarchar(128), @CurrntEmpTimeZoneDesc varchar(100)',
    --      @Module=@Module, @StartAt=@StartAt,     @EndAt=@EndAt,       @PK_Key=@PK_Key,       @PK_Value=@PK_Value,     @CurrntEmpTimeZoneDesc = @CurrntEmpTimeZoneDesc;
    
    EXEC sp_executesql
        @sql,
        N'@Module sysname, @StartAt datetime2(3), @EndAt datetime2(3), @PK_Key nvarchar(128), @PK_Value nvarchar(128), @SubPK_Key nvarchar(128), @SubPK_Value nvarchar(128), @CurrntEmpTimeZoneDesc varchar(100)',
          @Module=@Module, @StartAt=@StartAt,     @EndAt=@EndAt,       @PK_Key=@PK_Key,       @PK_Value=@PK_Value,     @SubPK_Key=@SubPK_Key,    @SubPK_Value=@SubPK_Value,  @CurrntEmpTimeZoneDesc = @CurrntEmpTimeZoneDesc;
      
    END TRY    
  
    BEGIN CATCH  
  
    DECLARE @ErrorLogID int,  
            @DatabaseName varchar(100) = DB_NAME()  
            -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
            ,  
            @AdhocComments varchar(150) = '[usp_Get_CommonAuditLogHistory]',  
            @ProcedureParameters varchar(3000) = '@Parameter1 = ''' + CAST(ISNULL(@Module, '') AS varchar(100)) +  
            '@Parameter2 = ''' + CAST(ISNULL(@PK_Key, '') AS varchar(100)) +  
            '@Parameter3 = ''' + CAST(ISNULL(@PK_Value, '') AS varchar(100)) +  
            '@Parameter4 = ''' + CAST(ISNULL(@StartAt, '') AS varchar(100)) +  
            '@Parameter5 = ''' + CAST(ISNULL(@EndAt, '') AS varchar(100)) +  
            '@Parameter6 = ''' + CAST(ISNULL(@SortDir, '') AS varchar(100)),  
            @ApplicationName varchar(100) = 'PAS'  
  
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