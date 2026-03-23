CREATE TABLE [dbo].[VendorContact] (
    [VendorContactId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]          BIGINT        NOT NULL,
    [ContactId]         BIGINT        NOT NULL,
    [Tag]               VARCHAR (255) CONSTRAINT [DF__VendorConta__Tag__24134F1B] DEFAULT ('') NOT NULL,
    [IsDefaultContact]  BIT           NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [VendorContact_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [VendorContact_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [VendorContact_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [VC_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ContactTagId]      BIGINT        NULL,
    [Attention]         VARCHAR (250) NULL,
    [IsRestrictedParty] BIT           NULL,
    CONSTRAINT [PK_VendorContact] PRIMARY KEY CLUSTERED ([VendorContactId] ASC),
    CONSTRAINT [FK_VendorContact_Contact] FOREIGN KEY ([ContactId]) REFERENCES [dbo].[Contact] ([ContactId]),
    CONSTRAINT [FK_VendorContact_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_VendorContact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorContact_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);






GO


CREATE TRIGGER [dbo].[Trg_VendorContactAudit]

   ON  [dbo].[VendorContact]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorContactAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO

     
  CREATE   TRIGGER [dbo].[trg_Audit_dbo_VendorContact]
        ON [dbo].[VendorContact]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[VendorContactId],d.[VendorId],d.[ContactId],d.[IsDefaultContact],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[ContactTagId],d.[Attention],d.[IsRestrictedParty] FROM deleted d),
            i AS (SELECT i.[VendorContactId],i.[VendorId],i.[ContactId],i.[IsDefaultContact],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[ContactTagId],i.[Attention],i.[IsRestrictedParty] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.VendorContactId, d.VendorContactId ) AS VendorContactId,
                    COALESCE(i.ContactId, d.ContactId) AS ContactId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.VendorContactId IS NOT NULL AND d.VendorContactId IS NOT NULL THEN 'U'
                        WHEN i.VendorContactId IS NOT NULL AND d.VendorContactId IS NULL     THEN 'I'
                        WHEN i.VendorContactId IS NULL     AND d.VendorContactId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.VendorContactId, d.VendorContactId) AS VendorContactId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.VendorContactId = d.VendorContactId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.VendorContactId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorContact'
                      AND ign.ColumnName = N'VendorContactId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.VendorContactId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'VendorContact'
                      AND ign.ColumnName = N'VendorContactId'
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
                    o.OldValue,
                    n.NewValue,
                    p.Action,
                    p.ContactId
                FROM paired p
                LEFT JOIN oldv o
                    ON o.VendorContactId = p.VendorContactId
                LEFT JOIN newv n
                    ON n.VendorContactId = p.VendorContactId
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action,
                    p.ContactId
                FROM paired p
                LEFT JOIN newv n
                    ON n.VendorContactId = p.VendorContactId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.VendorContactId = p.VendorContactId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue , ReferenceId)
            SELECT
                N'dbo' AS SchemaName,
                N'VendorContact' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue,
                COALESCE(i2.ContactId, d2.ContactId) AS ReferenceId
            FROM merged m
            LEFT JOIN inserted i2 ON i2.VendorContactId = TRY_CAST(JSON_VALUE(m.PKJson, '$.VendorContactId') AS BIGINT)
            LEFT JOIN deleted d2 ON d2.VendorContactId = TRY_CAST(JSON_VALUE(m.PKJson, '$.VendorContactId') AS BIGINT)
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