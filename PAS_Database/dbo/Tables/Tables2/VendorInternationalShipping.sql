CREATE TABLE [dbo].[VendorInternationalShipping] (
    [VendorInternationalShippingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorId]                      BIGINT          NOT NULL,
    [ExportLicense]                 VARCHAR (200)   NULL,
    [StartDate]                     DATETIME2 (7)   NULL,
    [Amount]                        DECIMAL (18, 3) NULL,
    [IsPrimary]                     BIT             NOT NULL,
    [Description]                   VARCHAR (250)   NULL,
    [ExpirationDate]                DATETIME        NULL,
    [ShipToCountryId]               SMALLINT        NOT NULL,
    [MasterCompanyId]               INT             NOT NULL,
    [CreatedBy]                     VARCHAR (256)   NULL,
    [UpdatedBy]                     VARCHAR (256)   NULL,
    [CreatedDate]                   DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)   NOT NULL,
    [IsActive]                      BIT             CONSTRAINT [VendorInternationalShipping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT             CONSTRAINT [ VendorInternationalShipping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorInternationalShipping] PRIMARY KEY CLUSTERED ([VendorInternationalShippingId] ASC),
    CONSTRAINT [FK_VendorInternationalShipping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorInternationalShipping_ShipToCountry] FOREIGN KEY ([ShipToCountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_VendorInternationalShipping_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);




GO


CREATE TRIGGER [dbo].[Trg_VendorInternationalShippingDelete]

   ON  [dbo].[VendorInternationalShipping]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[VendorInternationalShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO


CREATE TRIGGER [dbo].[Trg_VendorInternationalShippingAudit]

   ON  [dbo].[VendorInternationalShipping]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[VendorInternationalShippingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_VendorInternationalShipping]
        ON [dbo].[VendorInternationalShipping]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[VendorInternationalShippingId],d.[VendorId],d.[ExportLicense],d.[StartDate],d.[Amount],d.[IsPrimary],d.[Description],d.[ExpirationDate],d.[ShipToCountryId],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[VendorInternationalShippingId],i.[VendorId],i.[ExportLicense],i.[StartDate],i.[Amount],i.[IsPrimary],i.[Description],i.[ExpirationDate],i.[ShipToCountryId],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.VendorInternationalShippingId, d.VendorInternationalShippingId ) AS VendorInternationalShippingId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.VendorInternationalShippingId IS NOT NULL AND d.VendorInternationalShippingId IS NOT NULL THEN 'U'
                        WHEN i.VendorInternationalShippingId IS NOT NULL AND d.VendorInternationalShippingId IS NULL     THEN 'I'
                        WHEN i.VendorInternationalShippingId IS NULL     AND d.VendorInternationalShippingId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.VendorInternationalShippingId, d.VendorInternationalShippingId) AS VendorInternationalShippingId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.VendorInternationalShippingId = d.VendorInternationalShippingId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.VendorInternationalShippingId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorInternationalShipping'
                      AND ign.ColumnName = N'VendorInternationalShippingId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.VendorInternationalShippingId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorInternationalShipping'
                      AND ign.ColumnName = N'VendorInternationalShippingId'
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
                    ON o.VendorInternationalShippingId = p.VendorInternationalShippingId
                LEFT JOIN newv n
                    ON n.VendorInternationalShippingId = p.VendorInternationalShippingId
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
                    ON n.VendorInternationalShippingId = p.VendorInternationalShippingId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.VendorInternationalShippingId = p.VendorInternationalShippingId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'VendorInternationalShipping' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'ShipToCountryId' THEN ctOld.countries_name
                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'ShipToCountryId' THEN ctNew.countries_name
                    ELSE m.NewValue
                END AS NewValue
            FROM merged m
            LEFT JOIN DBO.Countries ctOld WITH (NOLOCK) ON m.ColumnName = 'ShipToCountryId'AND TRY_CAST(m.OldValue AS bigint)  = ctOld.countries_id
            LEFT JOIN DBO.Countries ctNew WITH (NOLOCK) ON m.ColumnName = 'ShipToCountryId'AND TRY_CAST(m.NewValue AS bigint)  = ctNew.countries_id
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