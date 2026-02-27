CREATE TABLE [dbo].[CustomerContact] (
    [CustomerContactId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]        BIGINT        NOT NULL,
    [ContactId]         BIGINT        NOT NULL,
    [IsDefaultContact]  BIT           CONSTRAINT [CustomerContact_DC_IsDefaultContact] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_CustomerContact_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_CustomerContact_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [CustomerContact_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           DEFAULT ((0)) NOT NULL,
    [IsRestrictedParty] BIT           NULL,
    CONSTRAINT [PK_CustomerContact] PRIMARY KEY CLUSTERED ([CustomerContactId] ASC),
    CONSTRAINT [FK_CustomerContact_Contact] FOREIGN KEY ([ContactId]) REFERENCES [dbo].[Contact] ([ContactId]),
    CONSTRAINT [FK_CustomerContact_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerContact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




---------------



CREATE TRIGGER [dbo].[trg_Audit_dbo_CustomerContact]
ON [dbo].[CustomerContact]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[CustomerContactId],d.[CustomerId],d.[ContactId],d.[IsDefaultContact],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[IsRestrictedParty] FROM deleted d),
    i AS (SELECT i.[CustomerContactId],i.[CustomerId],i.[ContactId],i.[IsDefaultContact],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[IsRestrictedParty] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.CustomerContactId, d.CustomerContactId ) AS CustomerContactId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.CustomerContactId IS NOT NULL AND d.CustomerContactId IS NOT NULL THEN 'U'
                WHEN i.CustomerContactId IS NOT NULL AND d.CustomerContactId IS NULL     THEN 'I'
                WHEN i.CustomerContactId IS NULL     AND d.CustomerContactId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.CustomerContactId, d.CustomerContactId) AS CustomerContactId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.CustomerContactId = d.CustomerContactId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.CustomerContactId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerContact'
                AND ign.ColumnName = N'CustomerContactId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.CustomerContactId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerContact'
                AND ign.ColumnName = N'CustomerContactId'
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
            ON o.CustomerContactId = p.CustomerContactId
        LEFT JOIN newv n
            ON n.CustomerContactId = p.CustomerContactId
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
            ON n.CustomerContactId = p.CustomerContactId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.CustomerContactId = p.CustomerContactId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'CustomerContact' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        m.OldValue,
        m.NewValue
    FROM merged m
    WHERE
        m.ColumnName <> 'CustomerContactId' and (
        (m.Action = 'U' AND (
                (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
            OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
            OR (m.OldValue <> m.NewValue)
        ))
        OR
        (m.Action = 'I' AND m.NewValue IS NOT NULL)
        OR
        (m.Action = 'D' AND m.OldValue IS NOT NULL));
END;