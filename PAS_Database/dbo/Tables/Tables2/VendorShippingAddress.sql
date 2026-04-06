CREATE TABLE [dbo].[VendorShippingAddress] (
    [VendorShippingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]                BIGINT        NOT NULL,
    [AddressId]               BIGINT        NOT NULL,
    [IsPrimary]               BIT           CONSTRAINT [DF__VendorShi__IsPri__5A45429A] DEFAULT ((0)) NOT NULL,
    [SiteName]                VARCHAR (100) NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) CONSTRAINT [VendorShippingAddress_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) CONSTRAINT [VendorShippingAddress_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT           CONSTRAINT [VendorShippingAddress_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [VendorShippingAddress_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ContactTagId]            BIGINT        NULL,
    [Attention]               VARCHAR (250) NULL,
    CONSTRAINT [PK_VendorShippingAddress] PRIMARY KEY CLUSTERED ([VendorShippingAddressId] ASC),
    CONSTRAINT [FK_VendorShippingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_VendorShippingAddress_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_VendorShippingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorShippingAddress_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);




GO
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_VendorShippingAddress]
        ON [dbo].[VendorShippingAddress]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[VendorShippingAddressId],d.[VendorId],d.[AddressId],d.[IsPrimary],d.[SiteName],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[ContactTagId],d.[Attention] FROM deleted d),
            i AS (SELECT i.[VendorShippingAddressId],i.[VendorId],i.[AddressId],i.[IsPrimary],i.[SiteName],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[ContactTagId],i.[Attention] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.VendorShippingAddressId, d.VendorShippingAddressId ) AS VendorShippingAddressId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.VendorShippingAddressId IS NOT NULL AND d.VendorShippingAddressId IS NOT NULL THEN 'U'
                        WHEN i.VendorShippingAddressId IS NOT NULL AND d.VendorShippingAddressId IS NULL     THEN 'I'
                        WHEN i.VendorShippingAddressId IS NULL     AND d.VendorShippingAddressId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.VendorShippingAddressId, d.VendorShippingAddressId) AS VendorShippingAddressId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.VendorShippingAddressId = d.VendorShippingAddressId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.VendorShippingAddressId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorShippingAddress'
                      AND ign.ColumnName = N'VendorShippingAddressId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.VendorShippingAddressId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorShippingAddress'
                      AND ign.ColumnName = N'VendorShippingAddressId'
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
                    ON o.VendorShippingAddressId = p.VendorShippingAddressId
                LEFT JOIN newv n
                    ON n.VendorShippingAddressId = p.VendorShippingAddressId
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
                    ON n.VendorShippingAddressId = p.VendorShippingAddressId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.VendorShippingAddressId = p.VendorShippingAddressId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'VendorShippingAddress' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'ContactTagId' THEN contOld.TagName
                    WHEN m.ColumnName = 'AddressId' THEN ctOld.countries_name

                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'ContactTagId' THEN contNew.TagName
                    WHEN m.ColumnName = 'AddressId' THEN ctNew.countries_name
                    ELSE m.NewValue
                END AS NewValue
            FROM merged m
            LEFT JOIN DBO.ContactTag contOld WITH (NOLOCK) ON m.ColumnName = 'ContactTagId'AND TRY_CAST(m.OldValue AS bigint)  = contOld.ContactTagId
            LEFT JOIN DBO.ContactTag contNew WITH (NOLOCK) ON m.ColumnName = 'ContactTagId'AND TRY_CAST(m.NewValue AS bigint)  = contNew.ContactTagId
            LEFT JOIN DBO.Address adOld WITH (NOLOCK) ON m.ColumnName = 'AddressId'AND TRY_CAST(m.OldValue AS bigint)  = adOld.AddressId
            LEFT JOIN DBO.Countries ctOld WITH (NOLOCK) ON adOld.CountryId  = ctOld.countries_id
            LEFT JOIN DBO.Address adNew WITH (NOLOCK) ON m.ColumnName = 'AddressId'AND TRY_CAST(m.NewValue AS bigint)  = adNew.AddressId
            LEFT JOIN DBO.Countries ctNew WITH (NOLOCK) ON adNew.CountryId = ctNew.countries_id
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
                N'VendorShippingAddress',
                m.PKJson,
                x.ColumnName,
                m.Action,
                x.OldValue,
                x.NewValue
            FROM merged m
            LEFT JOIN DBO.Address adOld WITH (NOLOCK) ON m.ColumnName = 'AddressId'AND TRY_CAST(m.OldValue AS bigint)  = adOld.AddressId
            LEFT JOIN DBO.Address adNew WITH (NOLOCK) ON m.ColumnName = 'AddressId'AND TRY_CAST(m.NewValue AS bigint)  = adNew.AddressId
           
            CROSS APPLY (
                VALUES
                ('Line1', adOld.Line1, adNew.Line1),
                ('Line2', adOld.Line2, adNew.Line2),
                ('City', adOld.City, adNew.City),
                ('StateOrProvince', adOld.StateOrProvince, adNew.StateOrProvince),
                ('PostalCode', adOld.PostalCode, adNew.PostalCode)
            ) x (ColumnName, OldValue, NewValue)

            WHERE m.ColumnName = 'AddressId'
                AND (
                    (x.OldValue IS NULL AND x.NewValue IS NOT NULL)
                    OR (x.OldValue IS NOT NULL AND x.NewValue IS NULL)
                    OR (x.OldValue <> x.NewValue)
                );
        END;