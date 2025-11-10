/*************************************************************             
 ** File:   [dbo].[usp_Get_CommonAuditLogHistory]        
 ** Author:   HEMANT SALIYA    
 ** Description: Get Data for Common Audit Report   
 ** Purpose:           
 ** Date:   07-NOV-2025        
            
 ** PARAMETERS:             
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO		Date			Author				Change Description              
 ** --		--------		-------------		--------------------------------            
    1		07-NOV-2025		HEMANT SALIYA			Created  
       
--EXEC dbo.usp_Get_CommonAuditLogHistory @Module='WorkOrder', @PK_Key='WorkOrderId', @PK_Value=4482
--EXEC dbo.usp_Get_CommonAuditLogHistory @Module='Customer', @PK_Key='CustomerId', @PK_Value=4482
--EXEC dbo.usp_Get_CommonAuditLogHistory @Module='Vendor', @PK_Key='VendorId', @PK_Value=5418 
**************************************************************/ 

CREATE   PROC [dbo].[usp_Get_CommonAuditLogHistory]
    @Module     sysname       = NULL,       -- e.g. 'Customer' / 'Vendor' (maps to TableName)
    @PK_Key     nvarchar(128) = NULL,       -- e.g. 'CustomerId'
    @PK_Value   nvarchar(128) = NULL,       -- e.g. '7' (compared as NVARCHAR)
    @StartAt    datetime2(3)  = NULL,       -- inclusive
    @EndAt      datetime2(3)  = NULL,       -- exclusive
    @UseOld     bit           = 0,          -- 0 = pivot NewValue, 1 = pivot OldValue
    @SortDir    nvarchar(4)   = N'DESC'     -- ASC | DESC (by ChangedAt)
AS
BEGIN
    SET NOCOUNT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
    BEGIN TRY  
    -- Validate sort dir
    IF @SortDir NOT IN (N'ASC', N'DESC') SET @SortDir = N'DESC';

    ----------------------------------------------------------------
    -- Build dynamic column list from ColumnName in the filtered scope
    -- (ensures only relevant fields appear as pivoted columns)
    ----------------------------------------------------------------
    DECLARE @cols nvarchar(MAX);

    SELECT @cols =
        STRING_AGG(QUOTENAME(ColumnName), ',')
    FROM (
        SELECT DISTINCT ColumnName
        FROM [dbo].[AuditLog] WITH (NOLOCK)
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
    ) AS c;

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

    DECLARE @valExpr nvarchar(20) =
        CASE WHEN @UseOld = 1 THEN N'OldValue' ELSE N'NewValue' END;

    ----------------------------------------------------------------
    -- Dynamic pivot:
    --  - Deduplicate multiple rows for the same column at the same event
    --  - Pivot columns = each distinct ColumnName
    --  - Include a compact Actions string (e.g., 'I', 'U', 'D' or combination)
    ----------------------------------------------------------------
    DECLARE @sql nvarchar(MAX) =
        N';WITH S AS
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
              AND (@Module  IS NULL OR TableName = @Module)
              AND (@StartAt IS NULL OR ChangedAt >= @StartAt)
              AND (@EndAt   IS NULL OR ChangedAt <  @EndAt)
              AND (
                    @PK_Key IS NULL OR @PK_Value IS NULL
                    OR TRY_CONVERT(nvarchar(128), JSON_VALUE(PKJson, CONCAT(''$.'' , @PK_Key))) = @PK_Value
                  )
        ),
        Dedup AS
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
            p.TableName,
            p.PKJson,
            p.ChangedAt,
            a.AnyChangedBy AS ChangedBy,
            a.Actions,
            ' + REPLACE(@cols, '],[', '], p.[') + N'
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

    --PRINT @sql;

    EXEC sp_executesql
        @sql,
        N'@Module sysname, @StartAt datetime2(3), @EndAt datetime2(3), @PK_Key nvarchar(128), @PK_Value nvarchar(128)',
        @Module=@Module, @StartAt=@StartAt, @EndAt=@EndAt, @PK_Key=@PK_Key, @PK_Value=@PK_Value;
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