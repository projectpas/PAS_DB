CREATE TABLE [dbo].[UOMFamilyType] (
    [UOMFamilyTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100) NOT NULL,
    [Description]     VARCHAR (256) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_UOMFamilyType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_UOMFamilyType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_UOMFamilyType_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_UOMFamilyType_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [Code]            AS ([Name]) PERSISTED,
    CONSTRAINT [PK_UOMFamilyType] PRIMARY KEY CLUSTERED ([UOMFamilyTypeId] ASC),
    CONSTRAINT [Unique_UOMFamilyType_Name] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO


     CREATE     TRIGGER [dbo].[trg_Audit_dbo_UOMFamilyType]
        ON [dbo].[UOMFamilyType]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[UOMFamilyTypeId],d.[Code],d.[Name],d.[Description],d.[IsActive],d.[IsDeleted],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate] FROM deleted d),
            i AS (SELECT i.[UOMFamilyTypeId],i.[Code],i.[Name],i.[Description],i.[IsActive],i.[IsDeleted],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.UOMFamilyTypeId, d.UOMFamilyTypeId ) AS UOMFamilyTypeId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json,
                    CASE
                        WHEN i.UOMFamilyTypeId IS NOT NULL AND d.UOMFamilyTypeId IS NOT NULL THEN 'U'
                        WHEN i.UOMFamilyTypeId IS NOT NULL AND d.UOMFamilyTypeId IS NULL     THEN 'I'
                        WHEN i.UOMFamilyTypeId IS NULL     AND d.UOMFamilyTypeId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.UOMFamilyTypeId, d.UOMFamilyTypeId) AS UOMFamilyTypeId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.UOMFamilyTypeId = d.UOMFamilyTypeId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.UOMFamilyTypeId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'UOMFamilyType'
                      AND ign.ColumnName = N'UOMFamilyTypeId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.UOMFamilyTypeId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'UOMFamilyType'
                      AND ign.ColumnName = N'UOMFamilyTypeId'
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
                    ON o.UOMFamilyTypeId = p.UOMFamilyTypeId
                LEFT JOIN newv n
                    ON n.UOMFamilyTypeId = p.UOMFamilyTypeId
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
                    ON n.UOMFamilyTypeId = p.UOMFamilyTypeId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.UOMFamilyTypeId = p.UOMFamilyTypeId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'UOMFamilyType' AS TableName,
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
