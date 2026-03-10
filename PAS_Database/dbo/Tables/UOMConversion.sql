CREATE TABLE [dbo].[UOMConversion] (
    [UOMConversionId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FromUOM]         VARCHAR (100)   NULL,
    [ToUOM]           VARCHAR (100)   NULL,
    [Factor]          DECIMAL (18, 8) NULL,
    [IsMultiply]      BIT             NULL,
    [DecimalPlaces]   INT             NULL,
    [MasterCompanyId] INT             NULL,
    [CreatedBy]       VARCHAR (256)   NULL,
    [UpdatedBy]       VARCHAR (256)   NULL,
    [CreatedDate]     DATETIME2 (7)   NULL,
    [UpdatedDate]     DATETIME2 (7)   NULL,
    [IsActive]        BIT             NULL,
    [IsDeleted]       BIT             NULL,
    CONSTRAINT [PK_UOMConversion] PRIMARY KEY CLUSTERED ([UOMConversionId] ASC)
);


GO

     
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_UOMConversion]
        ON [dbo].[UOMConversion]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[UOMConversionId],d.[FromUOM],d.[ToUOM],d.[Factor],d.[IsMultiply],d.[DecimalPlaces],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[UOMConversionId],i.[FromUOM],i.[ToUOM],i.[Factor],i.[IsMultiply],i.[DecimalPlaces],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.UOMConversionId, d.UOMConversionId ) AS UOMConversionId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.UOMConversionId IS NOT NULL AND d.UOMConversionId IS NOT NULL THEN 'U'
                        WHEN i.UOMConversionId IS NOT NULL AND d.UOMConversionId IS NULL     THEN 'I'
                        WHEN i.UOMConversionId IS NULL     AND d.UOMConversionId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.UOMConversionId, d.UOMConversionId) AS UOMConversionId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.UOMConversionId = d.UOMConversionId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.UOMConversionId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'UOMConversion'
                      AND ign.ColumnName = N'UOMConversionId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.UOMConversionId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'UOMConversion'
                      AND ign.ColumnName = N'UOMConversionId'
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
                    ON o.UOMConversionId = p.UOMConversionId
                LEFT JOIN newv n
                    ON n.UOMConversionId = p.UOMConversionId
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
                    ON n.UOMConversionId = p.UOMConversionId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.UOMConversionId = p.UOMConversionId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'UOMConversion' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL);
        END;