CREATE TABLE [dbo].[TrainingName] (
    [TrainingNameId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256) NOT NULL,
    [Memo]            VARCHAR (MAX) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_TrainingName_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_TrainingName_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_TrainingName_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_TrainingName_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TrainingName] PRIMARY KEY CLUSTERED ([TrainingNameId] ASC)
);


GO
    CREATE     TRIGGER [dbo].[trg_Audit_dbo_TrainingName]
        ON [dbo].[TrainingName]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[TrainingNameId],d.[Name],d.[Memo],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[TrainingNameId],i.[Name],i.[Memo],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.TrainingNameId, d.TrainingNameId ) AS TrainingNameId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.TrainingNameId IS NOT NULL AND d.TrainingNameId IS NOT NULL THEN 'U'
                        WHEN i.TrainingNameId IS NOT NULL AND d.TrainingNameId IS NULL     THEN 'I'
                        WHEN i.TrainingNameId IS NULL     AND d.TrainingNameId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.TrainingNameId, d.TrainingNameId) AS TrainingNameId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.TrainingNameId = d.TrainingNameId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.TrainingNameId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'TrainingName'
                      AND ign.ColumnName = N'TrainingNameId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.TrainingNameId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'TrainingName'
                      AND ign.ColumnName = N'TrainingNameId'
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
                    ON o.TrainingNameId = p.TrainingNameId
                LEFT JOIN newv n
                    ON n.TrainingNameId = p.TrainingNameId
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
                    ON n.TrainingNameId = p.TrainingNameId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.TrainingNameId = p.TrainingNameId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'TrainingName' AS TableName,
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