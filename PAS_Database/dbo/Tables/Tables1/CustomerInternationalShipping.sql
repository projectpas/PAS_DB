CREATE TABLE [dbo].[CustomerInternationalShipping] (
    [CustomerInternationalShippingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerId]                      BIGINT          NOT NULL,
    [ExportLicense]                   VARCHAR (200)   NULL,
    [StartDate]                       DATETIME        NULL,
    [Amount]                          DECIMAL (18, 3) CONSTRAINT [DF_CustomerInternationalShipping_Amount] DEFAULT ((0)) NULL,
    [IsPrimary]                       BIT             CONSTRAINT [CustomerInternationalShipping_DC_IsPrimary] DEFAULT ((0)) NOT NULL,
    [Description]                     NVARCHAR (500)  NULL,
    [ExpirationDate]                  DATETIME        NULL,
    [ShipToCountryId]                 SMALLINT        NOT NULL,
    [MasterCompanyId]                 INT             NOT NULL,
    [CreatedBy]                       VARCHAR (256)   NOT NULL,
    [UpdatedBy]                       VARCHAR (256)   NOT NULL,
    [CreatedDate]                     DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)   NOT NULL,
    [IsActive]                        BIT             CONSTRAINT [CustomerInternationalShipping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT             CONSTRAINT [CustomerInternationalShipping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_InternationalShipping] PRIMARY KEY CLUSTERED ([CustomerInternationalShippingId] ASC),
    CONSTRAINT [FK_CustomerInternationalShipping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerInternationalShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_CustomerInternationalShipping_ShipToCountry] FOREIGN KEY ([ShipToCountryId]) REFERENCES [dbo].[Countries] ([countries_id])
);




GO


------------------------------

CREATE TRIGGER [dbo].[Trg_CustomerInternationalShippingAudit]

   ON  [dbo].[CustomerInternationalShipping]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerInternationalShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_CustomerInternationalShipping]
ON [dbo].[CustomerInternationalShipping]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[CustomerInternationalShippingId],d.[CustomerId],d.[ExportLicense],d.[StartDate],d.[Amount],d.[IsPrimary],d.[Description],d.[ExpirationDate],d.[ShipToCountryId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
    i AS (SELECT i.[CustomerInternationalShippingId],i.[CustomerId],i.[ExportLicense],i.[StartDate],i.[Amount],i.[IsPrimary],i.[Description],i.[ExpirationDate],i.[ShipToCountryId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.CustomerInternationalShippingId, d.CustomerInternationalShippingId ) AS CustomerInternationalShippingId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.CustomerInternationalShippingId IS NOT NULL AND d.CustomerInternationalShippingId IS NOT NULL THEN 'U'
                WHEN i.CustomerInternationalShippingId IS NOT NULL AND d.CustomerInternationalShippingId IS NULL     THEN 'I'
                WHEN i.CustomerInternationalShippingId IS NULL     AND d.CustomerInternationalShippingId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.CustomerInternationalShippingId, d.CustomerInternationalShippingId) AS CustomerInternationalShippingId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.CustomerInternationalShippingId = d.CustomerInternationalShippingId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.CustomerInternationalShippingId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerInternationalShipping'
                AND ign.ColumnName = N'CustomerInternationalShippingId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.CustomerInternationalShippingId,
            v.[key] AS ColumnName,
            v.value AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerInternationalShipping'
                AND ign.ColumnName = N'CustomerInternationalShippingId'
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
            ON o.CustomerInternationalShippingId = p.CustomerInternationalShippingId
        LEFT JOIN newv n
            ON n.CustomerInternationalShippingId = p.CustomerInternationalShippingId
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
            ON n.CustomerInternationalShippingId = p.CustomerInternationalShippingId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.CustomerInternationalShippingId = p.CustomerInternationalShippingId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'CustomerInternationalShipping' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        m.OldValue,
        m.NewValue
    FROM merged m
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