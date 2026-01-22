

CREATE   PROCEDURE dbo.InstallFieldChangeTriggers
  @ExcludeSchemas        nvarchar(max) = N'Audit,sys,INFORMATION_SCHEMA',
  @IncludeInsertDelete   bit = 0
AS
BEGIN
  SET NOCOUNT ON;

  ---------------------------------------------------------------------------
  -- Helpers
  ---------------------------------------------------------------------------
  DECLARE @schemas TABLE (name sysname PRIMARY KEY);
  ;WITH s AS (
    SELECT TRIM(value) AS v
    FROM string_split(@ExcludeSchemas, ',')
  )
  INSERT @schemas(name) SELECT TRY_CONVERT(sysname, v) FROM s WHERE v IS NOT NULL;

  ---------------------------------------------------------------------------
  -- Iterate every user table that has a Primary Key
  ---------------------------------------------------------------------------
  DECLARE cur CURSOR FAST_FORWARD FOR
  SELECT
    sch.name  AS SchemaName,
    t.name    AS TableName,
    t.object_id
  FROM sys.tables t
  JOIN sys.schemas sch ON sch.schema_id = t.schema_id
  WHERE t.is_ms_shipped = 0 AND t.name NOT like '%Audit%' and t.name NOT like '%IgnoreColumn%' and t.name NOT like '%HangFire%'
    AND t.name in ('Customer', 'Vendor', 'WorkOrder')
    AND NOT EXISTS (SELECT 1 FROM @schemas x WHERE x.name = sch.name)
    AND EXISTS (
        SELECT 1
        FROM sys.key_constraints k
        WHERE k.parent_object_id = t.object_id AND k.type = 'PK'
    );

  DECLARE
    @SchemaName sysname,
    @TableName  sysname,
    @ObjId      int;

  OPEN cur;
  FETCH NEXT FROM cur INTO @SchemaName, @TableName, @ObjId;

  WHILE @@FETCH_STATUS = 0
  BEGIN
    -------------------------------------------------------------------------
    -- Build PK JSON expression and column lists
    -------------------------------------------------------------------------
    DECLARE
      @pkExpr           nvarchar(max) = N'',
      @colsForJsonOld   nvarchar(max) = N'',
      @colsForJsonNew   nvarchar(max) = N'',
      @ignoreFilter     nvarchar(max) = N'';

    -- PK columns (ordered)
    ;WITH pkcols AS (
      SELECT c.name, ic.key_ordinal
      FROM sys.key_constraints k
      JOIN sys.index_columns ic ON ic.object_id = k.parent_object_id AND ic.index_id = k.unique_index_id
      JOIN sys.columns c ON c.object_id = k.parent_object_id AND c.column_id = ic.column_id
      WHERE k.parent_object_id = @ObjId AND k.type = 'PK'
      --ORDER BY ic.key_ordinal
    )
    --SELECT @pkExpr = STRING_AGG(
    --  ',"' + c.name + '":' +
    --  'QUOTENAME(CONVERT(nvarchar(4000), COALESCE(i.' + QUOTENAME(c.name) + ', d.' + QUOTENAME(c.name) + ')), ''"'' )'
    --  , '')
    --FROM pkcols c;

        SELECT @pkExpr = STRING_AGG(
          ',"' + c.name , '')
        FROM pkcols c;


    SET @pkExpr = STUFF(@pkExpr, 1, 1, '{') + '}';

    SET @pkExpr = REPLACE(REPLACE(REPLACE(@pkExpr, '{', ''), '}', ''), '"', '')

    -- Data columns to expose via JSON (exclude computed + rowversion + sparse XML etc.)
    ;WITH cols AS (
      SELECT c.name
      FROM sys.columns c
      WHERE c.object_id = @ObjId
        AND c.is_computed = 0
        AND c.is_ansi_padded = c.is_ansi_padded -- (no-op to keep simple)
        AND c.system_type_id NOT IN (34,35,99) -- image,text,ntext legacy
    )
    SELECT
      @colsForJsonOld = STRING_AGG('d.' + QUOTENAME(name), ','),
      @colsForJsonNew = STRING_AGG('i.' + QUOTENAME(name), ',')
    FROM cols;

    IF @colsForJsonOld IS NULL OR @colsForJsonNew IS NULL
      BEGIN
        SET @colsForJsonOld = N'';
        SET @colsForJsonNew = N'';
     END

    -- Ignore filter clause from dbo.IgnoreColumn
    SET @ignoreFilter = N'
      NOT EXISTS (
        SELECT 1
        FROM dbo.IgnoreColumn ign
        WHERE ign.SchemaName = N''' + @SchemaName + '''
          AND ign.TableName  = N''' + @TableName  + '''
          AND ign.ColumnName = v.[key]
      )';

    -------------------------------------------------------------------------
    -- Build trigger DDL
      --

      --d AS (SELECT d.* FROM deleted d),
      --i AS (SELECT i.* FROM inserted i),
    -------------------------------------------------------------------------

     DECLARE @SQL VARCHAR(max) = N'
     
     CREATE OR ALTER   TRIGGER [dbo].[trg_Audit_dbo_' + @TableName + ']
        ON ' + QUOTENAME(@SchemaName) + N'.' + QUOTENAME(@TableName) + N'
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT ' + CASE WHEN @colsForJsonOld<>'' THEN @colsForJsonOld ELSE 'd.*' END + ' FROM deleted d),
            i AS (SELECT ' + CASE WHEN @colsForJsonNew<>'' THEN @colsForJsonNew ELSE 'i.*' END + ' FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.' + @pkExpr + ', d.'+ @pkExpr +' ) AS '+@pkExpr+',
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.' + @pkExpr + ' IS NOT NULL AND d.' + @pkExpr + ' IS NOT NULL THEN ''U''
                        WHEN i.' + @pkExpr + ' IS NOT NULL AND d.' + @pkExpr + ' IS NULL     THEN ''I''
                        WHEN i.' + @pkExpr + ' IS NULL     AND d.' + @pkExpr + ' IS NOT NULL THEN ''D''
                    END AS Action,

                    (SELECT COALESCE(i.' + @pkExpr + ', d.' + @pkExpr + ') AS ' + @pkExpr + '
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.' + @pkExpr + ' = d.' + @pkExpr + '
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.' + @pkExpr + ',
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N''' + @SchemaName + '''
                      AND ign.TableName  = N''' + @TableName  + '''
                      AND ign.ColumnName = N''' + @pkExpr + '''
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.'+ @pkExpr +' ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N''' + @SchemaName + '''
                      AND ign.TableName  = N''' + @TableName  + '''
                      AND ign.ColumnName = N''' + @pkExpr + '''
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
                    o.OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN oldv o
                    ON o.'+ @pkExpr +' = p.'+ @pkExpr +'
                LEFT JOIN newv n
                    ON n.'+ @pkExpr +' = p.'+ @pkExpr +'
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action
                FROM paired p
                LEFT JOIN newv n
                    ON n.'+ @pkExpr +' = p.'+ @pkExpr +'
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.'+ @pkExpr +' = p.'+ @pkExpr +'
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N''' + @SchemaName + ''' AS SchemaName,
                N''' + @TableName  + ''' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                (m.Action = ''U'' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = ''I'' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = ''D'' AND m.OldValue IS NOT NULL);
        END;
        GO
     '

    
    PRINT @SQL
     --EXEC sys.sp_executesql @SQL;

    FETCH NEXT FROM cur INTO @SchemaName, @TableName, @ObjId;
  END

  CLOSE cur;
  DEALLOCATE cur;
END