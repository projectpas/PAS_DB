CREATE TABLE [dbo].[CustomerTaxTypeRateMapping] (
    [CustomerTaxTypeRateMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                   BIGINT        NOT NULL,
    [TaxTypeId]                    TINYINT       NOT NULL,
    [TaxRateId]                    BIGINT        NULL,
    [TaxType]                      VARCHAR (256) NOT NULL,
    [TaxRate]                      VARCHAR (256) NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_CustomerTaxTypeRateMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_CustomerTaxTypeRateMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [D_CTM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           CONSTRAINT [CustomerTaxTypeRateMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CustomerFinancialId]          BIGINT        NULL,
    [SiteId]                       BIGINT        NULL,
    [SiteName]                     VARCHAR (500) NULL,
    [ShipFromSiteId]               BIGINT        NULL,
    [ShipFromSiteName]             VARCHAR (50)  NULL,
    [IsRepair]                     BIT           NULL,
    [IsProductSale]                BIT           NULL,
    [IsTaxExempt]                  BIT           NULL,
    [TaxId]                        VARCHAR (256) NULL,
    CONSTRAINT [PK_CTTRMapping] PRIMARY KEY CLUSTERED ([CustomerTaxTypeRateMappingId] ASC),
    CONSTRAINT [FK_CustomerTaxTypeRateMapping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerTaxTypeRateMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CustomerIdTaxTypeRate] UNIQUE NONCLUSTERED ([CustomerId] ASC, [TaxRateId] ASC, [TaxTypeId] ASC, [SiteId] ASC, [ShipFromSiteId] ASC, [MasterCompanyId] ASC)
);
















GO


CREATE TRIGGER [dbo].[Trg_CustomerTaxTypeRateMappingDelete]

   ON  [dbo].[CustomerTaxTypeRateMapping]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[CustomerTaxTypeRateMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_CustomerTaxTypeRateMappingAudit]

   ON  [dbo].[CustomerTaxTypeRateMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[CustomerTaxTypeRateMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_CustomerTaxTypeRateMapping]
ON [dbo].[CustomerTaxTypeRateMapping]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH
    d AS
    (
        SELECT
            d.[CustomerTaxTypeRateMappingId],
            d.[CustomerId],
            d.[TaxTypeId],
            d.[TaxRateId],
            d.[TaxType],
            d.[TaxRate],
            d.[MasterCompanyId],
            d.[CreatedBy],
            d.[UpdatedBy],
            d.[CreatedDate],
            d.[UpdatedDate],
            d.[IsActive],
            d.[IsDeleted],
            d.[CustomerFinancialId],
            d.[SiteId],
            d.[SiteName],
            d.[ShipFromSiteId],
            d.[ShipFromSiteName],
            d.[IsRepair],
            d.[IsProductSale],
            d.[IsTaxExempt],
            d.[TaxId]
        FROM deleted d
    ),
    i AS
    (
        SELECT
            i.[CustomerTaxTypeRateMappingId],
            i.[CustomerId],
            i.[TaxTypeId],
            i.[TaxRateId],
            i.[TaxType],
            i.[TaxRate],
            i.[MasterCompanyId],
            i.[CreatedBy],
            i.[UpdatedBy],
            i.[CreatedDate],
            i.[UpdatedDate],
            i.[IsActive],
            i.[IsDeleted],
            i.[CustomerFinancialId],
            i.[SiteId],
            i.[SiteName],
            i.[ShipFromSiteId],
            i.[ShipFromSiteName],
            i.[IsRepair],
            i.[IsProductSale],
            i.[IsTaxExempt],
            i.[TaxId]
        FROM inserted i
    ),
    paired AS
    (
        SELECT
            COALESCE(
                i.CustomerTaxTypeRateMappingId,
                d.CustomerTaxTypeRateMappingId
            ) AS CustomerTaxTypeRateMappingId,

            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json,

            CASE
                WHEN i.CustomerTaxTypeRateMappingId IS NOT NULL
                     AND d.CustomerTaxTypeRateMappingId IS NOT NULL
                    THEN 'U'

                WHEN i.CustomerTaxTypeRateMappingId IS NOT NULL
                     AND d.CustomerTaxTypeRateMappingId IS NULL
                    THEN 'I'

                WHEN i.CustomerTaxTypeRateMappingId IS NULL
                     AND d.CustomerTaxTypeRateMappingId IS NOT NULL
                    THEN 'D'
            END AS Action,

            (
                SELECT
                    COALESCE(
                        i.CustomerTaxTypeRateMappingId,
                        d.CustomerTaxTypeRateMappingId
                    ) AS CustomerTaxTypeRateMappingId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
            ) AS PKJson

        FROM d
        FULL OUTER JOIN i
            ON i.CustomerTaxTypeRateMappingId = d.CustomerTaxTypeRateMappingId
    ),

    oldv AS
    (
        SELECT
            p.PKJson,
            p.CustomerTaxTypeRateMappingId,
            v.[key] AS ColumnName,
            v.value AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH (NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName = N'CustomerTaxTypeRateMapping'
                AND ign.ColumnName = N'CustomerTaxTypeRateMappingId'
        )
    ),

    newv AS
    (
        SELECT
            p.PKJson,
            p.CustomerTaxTypeRateMappingId,
            v.[key] AS ColumnName,
            v.value AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH (NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName = N'CustomerTaxTypeRateMapping'
                AND ign.ColumnName = N'CustomerTaxTypeRateMappingId'
        )
    ),

    merged AS
    (
        SELECT
            COALESCE(n.PKJson, o.PKJson) AS PKJson,
            COALESCE(n.ColumnName, o.ColumnName) AS ColumnName,
            o.OldValue,
            n.NewValue,
            p.Action
        FROM paired p
        LEFT JOIN oldv o
            ON o.CustomerTaxTypeRateMappingId = p.CustomerTaxTypeRateMappingId
        LEFT JOIN newv n
            ON n.CustomerTaxTypeRateMappingId = p.CustomerTaxTypeRateMappingId
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
            ON n.CustomerTaxTypeRateMappingId = p.CustomerTaxTypeRateMappingId
        WHERE NOT EXISTS
        (
            SELECT 1
            FROM oldv o2
            WHERE o2.CustomerTaxTypeRateMappingId = p.CustomerTaxTypeRateMappingId
                AND o2.ColumnName = n.ColumnName
        )
    )

    INSERT dbo.AuditLog
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
        N'dbo' AS SchemaName,
        N'CustomerTaxTypeRateMapping' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        m.OldValue,
        m.NewValue
    FROM merged m
    WHERE
        (m.Action = 'U' AND
        (
            (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
            OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
            OR (m.OldValue <> m.NewValue)
        ))
        OR
        (m.Action = 'I' AND m.NewValue IS NOT NULL)
        OR
        (m.Action = 'D' AND m.OldValue IS NOT NULL);
END;