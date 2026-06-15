CREATE TABLE [dbo].[RFQTraceability] (
    [RFQTraceabilityId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Traceability]      VARCHAR (500) NOT NULL,
    [Description]       VARCHAR (MAX) NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_RFQTraceability_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_RFQTraceability_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DF_RFQTraceability_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF_RFQTraceability_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RFQTraceability] PRIMARY KEY CLUSTERED ([RFQTraceabilityId] ASC)
);


GO

     
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_RFQTraceability]
        ON [dbo].[RFQTraceability]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[RFQTraceabilityId],d.[Traceability],d.[Description],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[RFQTraceabilityId],i.[Traceability],i.[Description],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.RFQTraceabilityId, d.RFQTraceabilityId ) AS RFQTraceabilityId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.RFQTraceabilityId IS NOT NULL AND d.RFQTraceabilityId IS NOT NULL THEN 'U'
                        WHEN i.RFQTraceabilityId IS NOT NULL AND d.RFQTraceabilityId IS NULL     THEN 'I'
                        WHEN i.RFQTraceabilityId IS NULL     AND d.RFQTraceabilityId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.RFQTraceabilityId, d.RFQTraceabilityId) AS RFQTraceabilityId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.RFQTraceabilityId = d.RFQTraceabilityId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.RFQTraceabilityId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'RFQTraceability'
                      AND ign.ColumnName = N'RFQTraceabilityId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.RFQTraceabilityId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'RFQTraceability'
                      AND ign.ColumnName = N'RFQTraceabilityId'
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
                    ON o.RFQTraceabilityId = p.RFQTraceabilityId
                LEFT JOIN newv n
                    ON n.RFQTraceabilityId = p.RFQTraceabilityId
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
                    ON n.RFQTraceabilityId = p.RFQTraceabilityId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.RFQTraceabilityId = p.RFQTraceabilityId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'RFQTraceability' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                m.ColumnName <> '<Enter your PrimaryKEY>' and (
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL));
        END;