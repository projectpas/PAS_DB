CREATE TABLE [dbo].[CustomerContactATAMapping] (
    [CustomerContactATAMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                  BIGINT        NOT NULL,
    [CustomerContactId]           BIGINT        NOT NULL,
    [ATAChapterId]                BIGINT        NULL,
    [ATAChapterCode]              VARCHAR (256) NULL,
    [ATAChapterName]              VARCHAR (250) NULL,
    [ATASubChapterId]             BIGINT        NULL,
    [ATASubChapterDescription]    VARCHAR (256) NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_CustomerContactATAMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_CustomerContactATAMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [D_CCAM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [CustomerContactATAMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ATASubChapterCode]           VARCHAR (250) NULL,
    [Level1]                      VARCHAR (50)  NULL,
    [Level2]                      VARCHAR (50)  NULL,
    [Level3]                      VARCHAR (50)  NULL,
    CONSTRAINT [PK_CCATAMapping] PRIMARY KEY CLUSTERED ([CustomerContactATAMappingId] ASC),
    CONSTRAINT [FK_CustomerContactATAMapping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerContactATAMapping_CustomerContact] FOREIGN KEY ([CustomerContactId]) REFERENCES [dbo].[CustomerContact] ([CustomerContactId]),
    CONSTRAINT [FK_CustomerContactATAMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_CustomerContactATAMapping]
ON [dbo].[CustomerContactATAMapping]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[CustomerContactATAMappingId],d.[CustomerId],d.[CustomerContactId],d.[ATAChapterId],d.[ATAChapterCode],d.[ATAChapterName],d.[ATASubChapterId],d.[ATASubChapterDescription],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[ATASubChapterCode],d.[Level1],d.[Level2],d.[Level3] FROM deleted d),
    i AS (SELECT i.[CustomerContactATAMappingId],i.[CustomerId],i.[CustomerContactId],i.[ATAChapterId],i.[ATAChapterCode],i.[ATAChapterName],i.[ATASubChapterId],i.[ATASubChapterDescription],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[ATASubChapterCode],i.[Level1],i.[Level2],i.[Level3] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.CustomerContactATAMappingId, d.CustomerContactATAMappingId ) AS CustomerContactATAMappingId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.CustomerContactATAMappingId IS NOT NULL AND d.CustomerContactATAMappingId IS NOT NULL THEN 'U'
                WHEN i.CustomerContactATAMappingId IS NOT NULL AND d.CustomerContactATAMappingId IS NULL     THEN 'I'
                WHEN i.CustomerContactATAMappingId IS NULL     AND d.CustomerContactATAMappingId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.CustomerContactATAMappingId, d.CustomerContactATAMappingId) AS CustomerContactATAMappingId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.CustomerContactATAMappingId = d.CustomerContactATAMappingId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.CustomerContactATAMappingId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerContactATAMapping'
                AND ign.ColumnName = N'CustomerContactATAMappingId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.CustomerContactATAMappingId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerContactATAMapping'
                AND ign.ColumnName = N'CustomerContactATAMappingId'
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
            ON o.CustomerContactATAMappingId = p.CustomerContactATAMappingId
        LEFT JOIN newv n
            ON n.CustomerContactATAMappingId = p.CustomerContactATAMappingId
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
            ON n.CustomerContactATAMappingId = p.CustomerContactATAMappingId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.CustomerContactATAMappingId = p.CustomerContactATAMappingId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'CustomerContactATAMapping' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        CASE
            WHEN m.ColumnName = 'CustomerContactId' THEN LTRIM(RTRIM(ISNULL(cOld.FirstName,'') + ' ' + ISNULL(cOld.LastName,'')))
            WHEN m.ColumnName IN ('Level1','Level2','Level3') THEN LTRIM(RTRIM(CONCAT(
                oldLevels.lvl1,
                CASE WHEN oldLevels.lvl2 IS NOT NULL AND oldLevels.lvl2 <> '' THEN '-' + oldLevels.lvl2 ELSE '' END,
                CASE WHEN oldLevels.lvl3 IS NOT NULL AND oldLevels.lvl3 <> '' THEN '-' + oldLevels.lvl3 ELSE '' END)))
            ELSE m.OldValue           
        END AS OldValue,        
        CASE 
            WHEN m.ColumnName = 'CustomerContactId' THEN LTRIM(RTRIM(ISNULL(cNew.FirstName,'') + ' ' + ISNULL(cNew.LastName,'')))
            WHEN m.ColumnName IN ('Level1','Level2','Level3') THEN LTRIM(RTRIM(CONCAT(
                newLevels.lvl1,
                CASE WHEN newLevels.lvl2 IS NOT NULL AND newLevels.lvl2 <> '' THEN '-' + newLevels.lvl2 ELSE '' END,
                CASE WHEN newLevels.lvl3 IS NOT NULL AND newLevels.lvl3 <> '' THEN '-' + newLevels.lvl3 ELSE '' END)))
            ELSE m.NewValue
        END AS NewValue
    FROM merged m
    INNER JOIN paired p ON p.PKJson = m.PKJson
    CROSS APPLY (
        SELECT 
            lvl1 = JSON_VALUE(p.old_row_json, '$.Level1'),
            lvl2 = JSON_VALUE(p.old_row_json, '$.Level2'),
            lvl3 = JSON_VALUE(p.old_row_json, '$.Level3')
    ) oldLevels
    CROSS APPLY (
        SELECT 
            lvl1 = JSON_VALUE(p.new_row_json, '$.Level1'),
            lvl2 = JSON_VALUE(p.new_row_json, '$.Level2'),
            lvl3 = JSON_VALUE(p.new_row_json, '$.Level3')
    ) newLevels
    LEFT JOIN dbo.CustomerContact ccOld WITH(NOLOCK) ON m.ColumnName = 'CustomerContactId' AND TRY_CAST(m.OldValue AS bigint) = ccOld.CustomerContactId
    LEFT JOIN dbo.Contact cOld WITH(NOLOCK) ON ccOld.ContactId = cOld.ContactId
    LEFT JOIN dbo.CustomerContact ccNew WITH(NOLOCK) ON m.ColumnName = 'CustomerContactId' AND TRY_CAST(m.NewValue AS bigint) = ccNew.CustomerContactId
    LEFT JOIN dbo.Contact cNew WITH(NOLOCK) ON ccNew.ContactId = cNew.ContactId
    WHERE 
    m.ColumnName <> 'CustomerContactATAMappingId' 
    AND (
        -- Level1/2/3 must compare full JSON group
        (
            m.ColumnName = 'Level1'
            AND (
                    ISNULL(oldLevels.lvl1, '') <> ISNULL(newLevels.lvl1, '') OR
                    ISNULL(oldLevels.lvl2, '') <> ISNULL(newLevels.lvl2, '') OR
                    ISNULL(oldLevels.lvl3, '') <> ISNULL(newLevels.lvl3, '')
                )
        )        
        -- Normal columns keep original logic
        OR
        (
            m.ColumnName NOT IN ('Level1','Level2','Level3')
            AND m.Action = 'U'
            AND (
                    (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                 OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                 OR (m.OldValue <> m.NewValue)
            )
        )
        OR (m.Action = 'I' AND m.NewValue IS NOT NULL)
        OR (m.Action = 'D' AND m.OldValue IS NOT NULL)
    );
END;