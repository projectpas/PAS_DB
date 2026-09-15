CREATE TABLE [dbo].[LeaseType] (
    [LeaseTypeId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [LeaseType]       VARCHAR (500) NOT NULL,
    [Description]     VARCHAR (MAX) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_LeaseType_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_LeaseType_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_LeaseType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_LeaseType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseType] PRIMARY KEY CLUSTERED ([LeaseTypeId] ASC)
);


GO
CREATE     TRIGGER [dbo].[trg_Audit_dbo_LeaseType]
        ON [dbo].[LeaseType]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[LeaseTypeId],d.[LeaseType],d.[Description],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[LeaseTypeId],i.[LeaseType],i.[Description],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.LeaseTypeId, d.LeaseTypeId ) AS LeaseTypeId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.LeaseTypeId IS NOT NULL AND d.LeaseTypeId IS NOT NULL THEN 'U'
                        WHEN i.LeaseTypeId IS NOT NULL AND d.LeaseTypeId IS NULL     THEN 'I'
                        WHEN i.LeaseTypeId IS NULL     AND d.LeaseTypeId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.LeaseTypeId, d.LeaseTypeId) AS LeaseTypeId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.LeaseTypeId = d.LeaseTypeId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.LeaseTypeId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'LeaseType'
                      AND ign.ColumnName = N'LeaseTypeTypeId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.LeaseTypeId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'LeaseType'
                      AND ign.ColumnName = N'LeaseTypeTypeId'
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
                    ON o.LeaseTypeId = p.LeaseTypeId
                LEFT JOIN newv n
                    ON n.LeaseTypeId = p.LeaseTypeId
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
                    ON n.LeaseTypeId = p.LeaseTypeId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.LeaseTypeId = p.LeaseTypeId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'LeaseType' AS TableName,
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