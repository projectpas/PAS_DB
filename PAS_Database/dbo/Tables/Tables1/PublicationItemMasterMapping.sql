CREATE TABLE [dbo].[PublicationItemMasterMapping] (
    [PublicationItemMasterMappingId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PublicationRecordId]            BIGINT         NOT NULL,
    [ItemMasterId]                   BIGINT         NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  NOT NULL,
    [IsActive]                       BIT            NOT NULL,
    [IsDeleted]                      BIT            NOT NULL,
    [Notes]                          NVARCHAR (MAX) NULL,
    CONSTRAINT [PK__ItemMast__730ECB10C16E3BE5] PRIMARY KEY CLUSTERED ([PublicationItemMasterMappingId] ASC),
    CONSTRAINT [FK_PublicationItemMasterMapping_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_PublicationItemMasterMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [PublicationItemMasterMappingConstraint] UNIQUE NONCLUSTERED ([PublicationRecordId] ASC, [ItemMasterId] ASC, [MasterCompanyId] ASC)
);






GO
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_PublicationItemMasterMapping]
        ON [dbo].[PublicationItemMasterMapping]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[PublicationItemMasterMappingId],d.[PublicationRecordId],d.[ItemMasterId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[Notes] FROM deleted d),
            i AS (SELECT i.[PublicationItemMasterMappingId],i.[PublicationRecordId],i.[ItemMasterId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[Notes] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.PublicationItemMasterMappingId, d.PublicationItemMasterMappingId ) AS PublicationItemMasterMappingId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.PublicationItemMasterMappingId IS NOT NULL AND d.PublicationItemMasterMappingId IS NOT NULL THEN 'U'
                        WHEN i.PublicationItemMasterMappingId IS NOT NULL AND d.PublicationItemMasterMappingId IS NULL     THEN 'I'
                        WHEN i.PublicationItemMasterMappingId IS NULL     AND d.PublicationItemMasterMappingId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.PublicationItemMasterMappingId, d.PublicationItemMasterMappingId) AS PublicationItemMasterMappingId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.PublicationItemMasterMappingId = d.PublicationItemMasterMappingId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.PublicationItemMasterMappingId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'PublicationItemMasterMapping'
                      AND ign.ColumnName = N'PublicationItemMasterMappingId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.PublicationItemMasterMappingId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'PublicationItemMasterMapping'
                      AND ign.ColumnName = N'PublicationItemMasterMappingId'
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
                    ON o.PublicationItemMasterMappingId = p.PublicationItemMasterMappingId
                LEFT JOIN newv n
                    ON n.PublicationItemMasterMappingId = p.PublicationItemMasterMappingId
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
                    ON n.PublicationItemMasterMappingId = p.PublicationItemMasterMappingId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.PublicationItemMasterMappingId = p.PublicationItemMasterMappingId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT INTO dbo.AuditLog
            (
                SchemaName,
                TableName,
                PKJson,
                ColumnName,
                Action,
                OldValue,
                NewValue
            )

            SELECT
                N'dbo',
                N'PublicationItemMasterMapping',
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'ItemMasterId'   THEN im.PartNumber 
                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'ItemMasterId' THEN imNew.PartNumber 
                    ELSE m.NewValue
                END AS NewValue
            FROM merged m
            LEFT JOIN DBO.ItemMaster im WITH (NOLOCK) ON m.ColumnName = 'ItemMasterId'AND TRY_CAST(m.OldValue AS bigint)  = im.ItemMasterId
            LEFT JOIN DBO.ItemMaster imNEw WITH (NOLOCK) ON m.ColumnName = 'ItemMasterId'AND TRY_CAST(m.NewValue AS bigint)  = imNEw.ItemMasterId
            WHERE
                (m.Action = 'U' AND (
                        (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                    OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                    OR (m.OldValue <> m.NewValue)
                ))
                OR (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR (m.Action = 'D' AND m.OldValue IS NOT NULL)

            UNION ALL

            SELECT
                N'dbo',
                N'PublicationItemMasterMapping',
                m.PKJson,
                x.ColumnName,
                m.Action,
                x.OldValue,
                x.NewValue
            FROM merged m
            LEFT JOIN dbo.ItemMaster imOld ON TRY_CAST(m.OldValue AS BIGINT) = imOld.ItemMasterId
            LEFT JOIN dbo.ItemGroup igOld ON imOld.ItemGroupId = igOld.ItemGroupId
            LEFT JOIN dbo.ItemClassification icOld ON imOld.ItemClassificationId = icOld.ItemClassificationId
            LEFT JOIN dbo.Manufacturer maOld WITH (NOLOCK) ON imOld.ManufacturerId = maOld.ManufacturerId


            LEFT JOIN dbo.ItemMaster imNew ON TRY_CAST(m.NewValue AS BIGINT) = imNew.ItemMasterId
            LEFT JOIN dbo.ItemGroup igNew ON imNew.ItemGroupId = igNew.ItemGroupId
            LEFT JOIN dbo.ItemClassification icNew ON imNew.ItemClassificationId = icNew.ItemClassificationId
            LEFT JOIN dbo.Manufacturer maNew WITH (NOLOCK) ON imNew.ManufacturerId = maNew.ManufacturerId

            CROSS APPLY (
                VALUES
                ('ManufacturerName', maOld.Name, maNew.Name),
                ('PartDescription', imOld.PartDescription, imNew.PartDescription),
                ('ItemGroupCode', igOld.ItemGroupCode, igNew.ItemGroupCode),
                ('ItemClassificationCode', icOld.ItemClassificationCode, icNew.ItemClassificationCode)
            ) x (ColumnName, OldValue, NewValue)

            WHERE m.ColumnName = 'ItemMasterId'
                AND (
                    (x.OldValue IS NULL AND x.NewValue IS NOT NULL)
                    OR (x.OldValue IS NOT NULL AND x.NewValue IS NULL)
                    OR (x.OldValue <> x.NewValue)
                );

        END;