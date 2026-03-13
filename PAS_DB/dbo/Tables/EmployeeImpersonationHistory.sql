CREATE TABLE [dbo].[EmployeeImpersonationHistory] (
    [EmployeeImpersonationId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [ImpersonatedByEmployeeId] BIGINT        NOT NULL,
    [ImpersonatedBy]           VARCHAR (256) NOT NULL,
    [ImpersonatedEmployeeId]   BIGINT        NOT NULL,
    [Impersonated]             VARCHAR (256) NOT NULL,
    [CompanyName]              VARCHAR (256) NOT NULL,
    [CompanyCode]              VARCHAR (100) NOT NULL,
    [CompanyId]                INT           NULL,
    [IsActive]                 BIT           DEFAULT ((1)) NOT NULL,
    [MasterCompanyId]          INT           NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME      NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedDate]              DATETIME      NULL,
    PRIMARY KEY CLUSTERED ([EmployeeImpersonationId] ASC)
);


GO
CREATE     TRIGGER [dbo].[trg_Audit_dbo_EmployeeImpersonationHistory]
        ON [dbo].[EmployeeImpersonationHistory]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[EmployeeImpersonationId],d.[ImpersonatedByEmployeeId],d.[ImpersonatedBy],d.[ImpersonatedEmployeeId],d.[Impersonated],d.[CompanyName],d.[CompanyCode],d.[CompanyId],d.[IsActive],d.[MasterCompanyId],d.[CreatedBy],d.[CreatedDate],d.[UpdatedBy],d.[UpdatedDate] FROM deleted d),
            i AS (SELECT i.[EmployeeImpersonationId],i.[ImpersonatedByEmployeeId],i.[ImpersonatedBy],i.[ImpersonatedEmployeeId],i.[Impersonated],i.[CompanyName],i.[CompanyCode],i.[CompanyId],i.[IsActive],i.[MasterCompanyId],i.[CreatedBy],i.[CreatedDate],i.[UpdatedBy],i.[UpdatedDate] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.EmployeeImpersonationId, d.EmployeeImpersonationId ) AS EmployeeImpersonationId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.EmployeeImpersonationId IS NOT NULL AND d.EmployeeImpersonationId IS NOT NULL THEN 'U'
                        WHEN i.EmployeeImpersonationId IS NOT NULL AND d.EmployeeImpersonationId IS NULL     THEN 'I'
                        WHEN i.EmployeeImpersonationId IS NULL     AND d.EmployeeImpersonationId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.ImpersonatedEmployeeId, d.ImpersonatedEmployeeId) AS ImpersonatedEmployeeId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.EmployeeImpersonationId = d.EmployeeImpersonationId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.EmployeeImpersonationId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'EmployeeImpersonationHistory'
                      AND ign.ColumnName = N'EmployeeImpersonationId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.EmployeeImpersonationId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'EmployeeImpersonationHistory'
                      AND ign.ColumnName = N'EmployeeImpersonationId'
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
                    ON o.EmployeeImpersonationId = p.EmployeeImpersonationId
                LEFT JOIN newv n
                    ON n.EmployeeImpersonationId = p.EmployeeImpersonationId
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
                    ON n.EmployeeImpersonationId = p.EmployeeImpersonationId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.EmployeeImpersonationId = p.EmployeeImpersonationId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'EmployeeImpersonationHistory' AS TableName,
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