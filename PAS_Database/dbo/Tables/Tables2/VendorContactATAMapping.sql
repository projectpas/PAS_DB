CREATE TABLE [dbo].[VendorContactATAMapping] (
    [VendorContactATAMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]                  BIGINT        NOT NULL,
    [VendorContactId]           BIGINT        NOT NULL,
    [ATAChapterId]              BIGINT        NOT NULL,
    [ATASubChapterId]           BIGINT        NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [D_VCAM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [ VendorContactATAMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Level1]                    VARCHAR (50)  NULL,
    [Level2]                    VARCHAR (50)  NULL,
    [Level3]                    VARCHAR (50)  NULL,
    CONSTRAINT [PK_VendorContactATAMapping] PRIMARY KEY CLUSTERED ([VendorContactATAMappingId] ASC),
    CONSTRAINT [FK_VendorContactATAMapping_ATASubChapter] FOREIGN KEY ([ATASubChapterId]) REFERENCES [dbo].[ATASubChapter] ([ATASubChapterId]),
    CONSTRAINT [FK_VendorContactATAMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorContactATAMapping_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_VendorContactATAMapping_VendorContact] FOREIGN KEY ([VendorContactId]) REFERENCES [dbo].[VendorContact] ([VendorContactId])
);






GO

GO
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_VendorContactATAMapping]
        ON [dbo].[VendorContactATAMapping]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[VendorContactATAMappingId],d.[VendorId],d.[VendorContactId],d.[ATAChapterId],d.[ATASubChapterId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[Level1],d.[Level2],d.[Level3] FROM deleted d),
            i AS (SELECT i.[VendorContactATAMappingId],i.[VendorId],i.[VendorContactId],i.[ATAChapterId],i.[ATASubChapterId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[Level1],i.[Level2],i.[Level3] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.VendorContactATAMappingId, d.VendorContactATAMappingId ) AS VendorContactATAMappingId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.VendorContactATAMappingId IS NOT NULL AND d.VendorContactATAMappingId IS NOT NULL THEN 'U'
                        WHEN i.VendorContactATAMappingId IS NOT NULL AND d.VendorContactATAMappingId IS NULL     THEN 'I'
                        WHEN i.VendorContactATAMappingId IS NULL     AND d.VendorContactATAMappingId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.VendorContactATAMappingId, d.VendorContactATAMappingId) AS VendorContactATAMappingId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.VendorContactATAMappingId = d.VendorContactATAMappingId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.VendorContactATAMappingId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorContactATAMapping'
                      AND ign.ColumnName = N'VendorContactATAMappingId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.VendorContactATAMappingId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorContactATAMapping'
                      AND ign.ColumnName = N'VendorContactATAMappingId'
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
                    ON o.VendorContactATAMappingId = p.VendorContactATAMappingId
                LEFT JOIN newv n
                    ON n.VendorContactATAMappingId = p.VendorContactATAMappingId
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
                    ON n.VendorContactATAMappingId = p.VendorContactATAMappingId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.VendorContactATAMappingId = p.VendorContactATAMappingId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'VendorContactATAMapping' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'VendorContactId'   THEN LTRIM(RTRIM(ISNULL(ctOld.FirstName,'') + ' ' + ISNULL(ctOld.MiddleName,'')+ ' ' + ISNULL(ctOld.LastName,'')))
                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'VendorContactId' THEN LTRIM(RTRIM(ISNULL(ctNew.FirstName,'') + ' ' + ISNULL(ctNew.MiddleName,'')+ ' ' + ISNULL(ctNew.LastName,'')))
                    ELSE m.NewValue
                END AS NewValue
            FROM merged m
            LEFT JOIN DBO.VendorContact vctOld WITH (NOLOCK) ON m.ColumnName = 'VendorContactId'AND TRY_CAST(m.OldValue AS bigint)  = vctOld.VendorContactId
            LEFT JOIN DBO.Contact ctOld WITH (NOLOCK) ON vctOld.ContactId = ctOld.ContactId
            LEFT JOIN DBO.VendorContact vctNew WITH (NOLOCK) ON m.ColumnName = 'VendorContactId'AND TRY_CAST(m.NewValue AS bigint)  = vctNew.VendorContactId
            LEFT JOIN DBO.Contact ctNew WITH (NOLOCK) ON vctNew.ContactId = ctNew.ContactId
   

            WHERE
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                ))
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL)
            
            UNION ALL

            SELECT
                N'dbo',
                N'VendorContactATAMapping',
                m.PKJson,
                x.ColumnName,
                m.Action,
                x.OldValue,
                x.NewValue
            FROM merged m
            LEFT JOIN dbo.VendorContactATAMapping VCOld WITH (NOLOCK) ON TRY_CAST(m.OldValue AS BIGINT) = VCOld.VendorContactATAMappingId
            LEFT JOIN dbo.VendorContactATAMapping VCNew WITH (NOLOCK) ON TRY_CAST(m.NewValue AS BIGINT) = VCNew.VendorContactATAMappingId
           
            CROSS APPLY (
                VALUES
                ('ATAChapter', LTRIM(RTRIM(ISNULL(VCOld.Level1,'') + '-' + ISNULL(VCOld.Level2,'')+ '-' + ISNULL(VCOld.Level3,''))), LTRIM(RTRIM(ISNULL(VCNew.Level1,'') + '-' + ISNULL(VCNew.Level2,'')+ '-' + ISNULL(VCNew.Level3,''))))
                
            ) x (ColumnName, OldValue, NewValue)

            WHERE m.ColumnName = 'VendorContactATAMappingId'
                AND (
                    (x.OldValue IS NULL AND x.NewValue IS NOT NULL)
                    OR (x.OldValue IS NOT NULL AND x.NewValue IS NULL)
                    OR (x.OldValue <> x.NewValue)
                );

        END;