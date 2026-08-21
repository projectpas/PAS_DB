CREATE TABLE [dbo].[CustomerBillingAddress] (
    [CustomerBillingAddressId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]               BIGINT        NOT NULL,
    [AddressId]                BIGINT        NOT NULL,
    [IsPrimary]                BIT           NOT NULL,
    [SiteName]                 VARCHAR (100) NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerBillingAddress_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_CustomerBillingAddress_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_CustomerBillingAddress_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [CustomerBillingAddress_DC_Delete] DEFAULT ((0)) NOT NULL,
    [TagName]                  VARCHAR (250) NULL,
    [ContactTagId]             BIGINT        NULL,
    [Attention]                VARCHAR (250) NULL,
    [InvDelPrefStatusId]       BIGINT        NULL,
    [Email]                    VARCHAR (50)  NULL,
    CONSTRAINT [PK_CustomerBillingAddress] PRIMARY KEY CLUSTERED ([CustomerBillingAddressId] ASC),
    CONSTRAINT [FK_CustomerBillingAddress_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_CustomerBillingAddress_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_CustomerBillingAddress_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerBillingAddress_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




CREATE TRIGGER [dbo].[Trg_CustomerBillingAddressAudit]

   ON  [dbo].[CustomerBillingAddress]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerBillingAddressAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO
CREATE     TRIGGER [dbo].[trg_Audit_dbo_CustomerBillingAddress]
        ON [dbo].[CustomerBillingAddress]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[CustomerBillingAddressId],d.[CustomerId],d.[AddressId],d.[IsPrimary],d.[SiteName],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[TagName],d.[ContactTagId],d.[Attention],d.[InvDelPrefStatusId],d.[Email] FROM deleted d),
            i AS (SELECT i.[CustomerBillingAddressId],i.[CustomerId],i.[AddressId],i.[IsPrimary],i.[SiteName],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[TagName],i.[ContactTagId],i.[Attention],i.[InvDelPrefStatusId],i.[Email] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.CustomerBillingAddressId, d.CustomerBillingAddressId ) AS CustomerBillingAddressId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.CustomerBillingAddressId IS NOT NULL AND d.CustomerBillingAddressId IS NOT NULL THEN 'U'
                        WHEN i.CustomerBillingAddressId IS NOT NULL AND d.CustomerBillingAddressId IS NULL     THEN 'I'
                        WHEN i.CustomerBillingAddressId IS NULL     AND d.CustomerBillingAddressId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.CustomerBillingAddressId, d.CustomerBillingAddressId) AS CustomerBillingAddressId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.CustomerBillingAddressId = d.CustomerBillingAddressId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.CustomerBillingAddressId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CustomerBillingAddress'
                      AND ign.ColumnName = N'CustomerBillingAddressId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.CustomerBillingAddressId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CustomerBillingAddress'
                      AND ign.ColumnName = N'CustomerBillingAddressId'
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
                    ON o.CustomerBillingAddressId = p.CustomerBillingAddressId
                LEFT JOIN newv n
                    ON n.CustomerBillingAddressId = p.CustomerBillingAddressId
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
                    ON n.CustomerBillingAddressId = p.CustomerBillingAddressId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.CustomerBillingAddressId = p.CustomerBillingAddressId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue, ReferenceId)
            SELECT
                N'dbo' AS SchemaName,
                N'CustomerBillingAddress' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue,
                COALESCE(i2.AddressId, d2.AddressId) AS ReferenceId
            FROM merged m
            LEFT JOIN inserted i2 ON i2.CustomerBillingAddressId = TRY_CAST(JSON_VALUE(m.PKJson, '$.CustomerBillingAddressId') AS BIGINT)
            LEFT JOIN deleted  d2 ON d2.CustomerBillingAddressId = TRY_CAST(JSON_VALUE(m.PKJson, '$.CustomerBillingAddressId') AS BIGINT)
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
                N'CustomerBillingAddress',
                m.PKJson,
                x.ColumnName,
                m.Action,
                CASE
                    WHEN x.ColumnName = 'CountryId' THEN ctOld.countries_name
                    ELSE x.OldValue
                END AS OldValue,
                CASE
                    WHEN x.ColumnName = 'CountryId' THEN ctNew.countries_name
                    ELSE x.NewValue
                END AS NewValue,
                COALESCE(i2.AddressId, d2.AddressId) AS ReferenceId
            FROM merged m
            LEFT JOIN inserted i2 ON i2.CustomerBillingAddressId = TRY_CAST(JSON_VALUE(m.PKJson, '$.CustomerBillingAddressId') AS BIGINT)
            LEFT JOIN deleted  d2 ON d2.CustomerBillingAddressId = TRY_CAST(JSON_VALUE(m.PKJson, '$.CustomerBillingAddressId') AS BIGINT)
            LEFT JOIN DBO.Address adOld WITH (NOLOCK) ON m.ColumnName = 'AddressId' AND TRY_CAST(m.OldValue AS bigint) = adOld.AddressId
            LEFT JOIN DBO.Countries ctOld WITH (NOLOCK) ON adOld.CountryId = ctOld.countries_id
            LEFT JOIN DBO.Address adNew WITH (NOLOCK) ON m.ColumnName = 'AddressId' AND TRY_CAST(m.NewValue AS bigint) = adNew.AddressId
            LEFT JOIN DBO.Countries ctNew WITH (NOLOCK) ON adNew.CountryId = ctNew.countries_id
            CROSS APPLY (
                VALUES
                ('Line1', adOld.Line1, adNew.Line1),
                ('Line2', adOld.Line2, adNew.Line2),
                ('City', adOld.City, adNew.City),
                ('StateOrProvince', adOld.StateOrProvince, adNew.StateOrProvince),
                ('PostalCode', adOld.PostalCode, adNew.PostalCode),
                ('CountryId', ctOld.countries_name, ctNew.countries_name)
            ) x (ColumnName, OldValue, NewValue)
            WHERE m.ColumnName = 'AddressId'
                AND (
                    (x.OldValue IS NULL AND x.NewValue IS NOT NULL)
                    OR (x.OldValue IS NOT NULL AND x.NewValue IS NULL)
                    OR (x.OldValue <> x.NewValue)
                );
        END;