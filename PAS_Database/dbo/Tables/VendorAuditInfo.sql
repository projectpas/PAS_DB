CREATE TABLE [dbo].[VendorAuditInfo] (
    [VendorAuditInfoId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]          BIGINT        NOT NULL,
    [VendorOrderTypeId] BIGINT        NOT NULL,
    [VendorAuditTypeId] BIGINT        NOT NULL,
    [FrequencyDays]     INT           NULL,
    [LastAuditDate]     DATETIME2 (7) NULL,
    [NextAuditDate]     DATETIME2 (7) NULL,
    [Expired]           VARCHAR (50)  NULL,
    [AuditFindings]     VARCHAR (MAX) NULL,
    [ActionsTaken]      VARCHAR (MAX) NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorAuditInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorAuditInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [VendorAuditInfo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [VendorAuditInfo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]   INT           NULL,
    CONSTRAINT [PK_VendorAuditInfo] PRIMARY KEY CLUSTERED ([VendorAuditInfoId] ASC),
    CONSTRAINT [FK_VendorAuditInfo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_VendorAuditInfo]
        ON [dbo].[VendorAuditInfo]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[VendorAuditInfoId],d.[VendorId],d.[VendorOrderTypeId],d.[VendorAuditTypeId],d.[FrequencyDays],d.[LastAuditDate],d.[NextAuditDate],d.[Expired],d.[AuditFindings],d.[ActionsTaken],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[MasterCompanyId] FROM deleted d),
            i AS (SELECT i.[VendorAuditInfoId],i.[VendorId],i.[VendorOrderTypeId],i.[VendorAuditTypeId],i.[FrequencyDays],i.[LastAuditDate],i.[NextAuditDate],i.[Expired],i.[AuditFindings],i.[ActionsTaken],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[MasterCompanyId] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.VendorAuditInfoId, d.VendorAuditInfoId ) AS VendorAuditInfoId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.VendorAuditInfoId IS NOT NULL AND d.VendorAuditInfoId IS NOT NULL THEN 'U'
                        WHEN i.VendorAuditInfoId IS NOT NULL AND d.VendorAuditInfoId IS NULL     THEN 'I'
                        WHEN i.VendorAuditInfoId IS NULL     AND d.VendorAuditInfoId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.VendorAuditInfoId, d.VendorAuditInfoId) AS VendorAuditInfoId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.VendorAuditInfoId = d.VendorAuditInfoId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.VendorAuditInfoId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorAuditInfo'
                      AND ign.ColumnName = N'VendorAuditInfoId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.VendorAuditInfoId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorAuditInfo'
                      AND ign.ColumnName = N'VendorAuditInfoId'
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
                    ON o.VendorAuditInfoId = p.VendorAuditInfoId
                LEFT JOIN newv n
                    ON n.VendorAuditInfoId = p.VendorAuditInfoId
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
                    ON n.VendorAuditInfoId = p.VendorAuditInfoId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.VendorAuditInfoId = p.VendorAuditInfoId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'VendorAuditInfo' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'VendorOrderTypeId' THEN vctOld.OrderTypeName
                    WHEN m.ColumnName = 'VendorAuditTypeId' THEN VATOld.VendorAuditType

                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'VendorOrderTypeId' THEN vctNew.OrderTypeName
                    WHEN m.ColumnName = 'VendorAuditTypeId' THEN VATNew.VendorAuditType
                    ELSE m.NewValue
                END AS NewValue
            FROM merged m
                LEFT JOIN DBO.[VendorOrderType] vctOld WITH (NOLOCK) ON m.ColumnName = 'VendorOrderTypeId'AND TRY_CAST(m.OldValue AS bigint)  = vctOld.VendorOrderTypeId
                LEFT JOIN DBO.[VendorOrderType] vctNew WITH (NOLOCK) ON m.ColumnName = 'VendorOrderTypeId'AND TRY_CAST(m.NewValue AS bigint)  = vctNew.VendorOrderTypeId
                LEFT JOIN DBO.[VendorAuditType] VATOld WITH (NOLOCK) ON m.ColumnName = 'VendorAuditTypeId'AND TRY_CAST(m.OldValue AS bigint)  = VATOld.VendorAuditTypeId
                LEFT JOIN DBO.[VendorAuditType] VATNew WITH (NOLOCK) ON m.ColumnName = 'VendorAuditTypeId'AND TRY_CAST(m.NewValue AS bigint)  = VATNew.VendorAuditTypeId
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