CREATE TABLE [dbo].[VendorCapability] (
    [VendorCapabilityId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorId]                  BIGINT          NOT NULL,
    [CapabilityTypeId]          INT             NOT NULL,
    [CapabilityTypeName]        VARCHAR (100)   NULL,
    [ItemMasterId]              BIGINT          NOT NULL,
    [CapabilityTypeDescription] VARCHAR (256)   NULL,
    [VendorRanking]             INT             NOT NULL,
    [IsPMA]                     BIT             CONSTRAINT [DF__VendorCap__IsPMA__597119F2] DEFAULT ((0)) NOT NULL,
    [IsDER]                     BIT             CONSTRAINT [DF__VendorCap__IsDER__5A653E2B] DEFAULT ((0)) NOT NULL,
    [Cost]                      DECIMAL (18, 2) NULL,
    [TAT]                       INT             NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [VendorCapabiliy_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [VendorCapabiliy_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [VendorCapabiliy_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [VendorCapabiliy_DC_Delete] DEFAULT ((0)) NOT NULL,
    [PartNumber]                VARCHAR (100)   NULL,
    [PartDescription]           VARCHAR (255)   NULL,
    [ManufacturerId]            BIGINT          NULL,
    [ManufacturerName]          VARCHAR (100)   NULL,
    [CostDate]                  DATETIME        NULL,
    [CurrencyId]                INT             NULL,
    [Currency]                  VARCHAR (50)    NULL,
    [EmployeeId]                INT             NULL,
    CONSTRAINT [PK_VendorCapabiliy] PRIMARY KEY CLUSTERED ([VendorCapabilityId] ASC),
    CONSTRAINT [FK_VendorCapability_CapabilityTypeId] FOREIGN KEY ([CapabilityTypeId]) REFERENCES [dbo].[CapabilityType] ([CapabilityTypeId]),
    CONSTRAINT [FK_VendorCapability_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_VendorCapability_ManufactureId] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_VendorCapabiliy_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorCapabiliy_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [Unique_VendorCapability] UNIQUE NONCLUSTERED ([VendorId] ASC, [CapabilityTypeId] ASC, [ItemMasterId] ASC, [MasterCompanyId] ASC, [IsPMA] ASC, [IsDER] ASC)
);




GO

     
     CREATE   TRIGGER [dbo].[trg_Audit_dbo_VendorCapability]
        ON [dbo].[VendorCapability]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[VendorCapabilityId],d.[VendorId],d.[CapabilityTypeId],d.[CapabilityTypeName],d.[ItemMasterId],d.[CapabilityTypeDescription],d.[VendorRanking],d.[IsPMA],d.[IsDER],d.[Cost],d.[TAT],d.[Memo],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[PartNumber],d.[PartDescription],d.[ManufacturerId],d.[ManufacturerName],d.[CostDate],d.[CurrencyId],d.[Currency],d.[EmployeeId] FROM deleted d),
            i AS (SELECT i.[VendorCapabilityId],i.[VendorId],i.[CapabilityTypeId],i.[CapabilityTypeName],i.[ItemMasterId],i.[CapabilityTypeDescription],i.[VendorRanking],i.[IsPMA],i.[IsDER],i.[Cost],i.[TAT],i.[Memo],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[PartNumber],i.[PartDescription],i.[ManufacturerId],i.[ManufacturerName],i.[CostDate],i.[CurrencyId],i.[Currency],i.[EmployeeId] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.VendorCapabilityId, d.VendorCapabilityId ) AS VendorCapabilityId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.VendorCapabilityId IS NOT NULL AND d.VendorCapabilityId IS NOT NULL THEN 'U'
                        WHEN i.VendorCapabilityId IS NOT NULL AND d.VendorCapabilityId IS NULL     THEN 'I'
                        WHEN i.VendorCapabilityId IS NULL     AND d.VendorCapabilityId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.VendorCapabilityId, d.VendorCapabilityId) AS VendorCapabilityId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.VendorCapabilityId = d.VendorCapabilityId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.VendorCapabilityId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorCapability'
                      AND ign.ColumnName = N'VendorCapabilityId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.VendorCapabilityId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorCapability'
                      AND ign.ColumnName = N'VendorCapabilityId'
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
                    ON o.VendorCapabilityId = p.VendorCapabilityId
                LEFT JOIN newv n
                    ON n.VendorCapabilityId = p.VendorCapabilityId
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
                    ON n.VendorCapabilityId = p.VendorCapabilityId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.VendorCapabilityId = p.VendorCapabilityId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'VendorCapability' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'ItemMasterId'   THEN imOld.PartNumber 
                    WHEN m.ColumnName = 'CapabilityTypeId'   THEN vcatOld.CapabilityTypeDesc 
                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'ItemMasterId' THEN imNew.PartNumber 
                    WHEN m.ColumnName = 'CapabilityTypeId' THEN vcatNEw.CapabilityTypeDesc 
                    ELSE m.NewValue
                END AS NewValue
            FROM merged m
            LEFT JOIN DBO.ItemMaster imOld WITH (NOLOCK) ON m.ColumnName = 'ItemMasterId'AND TRY_CAST(m.OldValue AS bigint)  = imOld.ItemMasterId
            LEFT JOIN DBO.ItemMaster imNEw WITH (NOLOCK) ON m.ColumnName = 'ItemMasterId'AND TRY_CAST(m.NewValue AS bigint)  = imNEw.ItemMasterId
            LEFT JOIN DBO.CapabilityType vcatOld WITH (NOLOCK) ON m.ColumnName = 'CapabilityTypeId'AND TRY_CAST(m.OldValue AS bigint)  = vcatOld.CapabilityTypeId
            LEFT JOIN DBO.CapabilityType vcatNEw WITH (NOLOCK) ON m.ColumnName = 'CapabilityTypeId'AND TRY_CAST(m.NewValue AS bigint)  = vcatNEw.CapabilityTypeId


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
                N'PublicationItemMasterMapping',
                m.PKJson,
                x.ColumnName,
                m.Action,
                x.OldValue,
                x.NewValue
            FROM merged m
            LEFT JOIN dbo.ItemMaster imOld ON TRY_CAST(m.OldValue AS BIGINT) = imOld.ItemMasterId
            LEFT JOIN dbo.ItemClassification icOld ON imOld.ItemClassificationId = icOld.ItemClassificationId
            LEFT JOIN dbo.Manufacturer maOld WITH (NOLOCK) ON imOld.ManufacturerId = maOld.ManufacturerId


            LEFT JOIN dbo.ItemMaster imNew ON TRY_CAST(m.NewValue AS BIGINT) = imNew.ItemMasterId
            LEFT JOIN dbo.ItemClassification icNew ON imNew.ItemClassificationId = icNew.ItemClassificationId
            LEFT JOIN dbo.Manufacturer maNew WITH (NOLOCK) ON imNew.ManufacturerId = maNew.ManufacturerId

            CROSS APPLY (
                VALUES
                ('ManufacturerName', maOld.Name, maNew.Name),
                ('PartDescription', imOld.PartDescription, imNew.PartDescription),
                ('ItemClassificationCode', icOld.ItemClassificationCode, icNew.ItemClassificationCode)
            ) x (ColumnName, OldValue, NewValue)

            WHERE m.ColumnName = 'ItemMasterId'
                AND (
                    (x.OldValue IS NULL AND x.NewValue IS NOT NULL)
                    OR (x.OldValue IS NOT NULL AND x.NewValue IS NULL)
                    OR (x.OldValue <> x.NewValue)
                );

        END;