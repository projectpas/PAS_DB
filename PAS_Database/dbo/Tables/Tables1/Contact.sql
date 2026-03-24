CREATE TABLE [dbo].[Contact] (
    [ContactId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [Prefix]          VARCHAR (20)   NULL,
    [FirstName]       VARCHAR (100)  NOT NULL,
    [LastName]        VARCHAR (30)   NOT NULL,
    [MiddleName]      VARCHAR (30)   NULL,
    [Suffix]          VARCHAR (20)   NULL,
    [ContactTitle]    VARCHAR (30)   NULL,
    [WorkPhone]       VARCHAR (20)   NULL,
    [WorkPhoneExtn]   VARCHAR (20)   NULL,
    [MobilePhone]     VARCHAR (20)   NULL,
    [AlternatePhone]  VARCHAR (20)   NULL,
    [Fax]             VARCHAR (20)   NULL,
    [Email]           VARCHAR (200)  NULL,
    [WebsiteURL]      VARCHAR (200)  NULL,
    [Notes]           NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Contact_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Contact_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Contact_DC_Active] DEFAULT ((1)) NOT NULL,
    [Tag]             VARCHAR (255)  CONSTRAINT [DF__Contact__Tag__10416098] DEFAULT ('') NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Contact_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ContactTagId]    BIGINT         NULL,
    [Attention]       VARCHAR (250)  NULL,
    CONSTRAINT [PK_Contact] PRIMARY KEY CLUSTERED ([ContactId] ASC),
    CONSTRAINT [FK_Contact_ContactTagId] FOREIGN KEY ([ContactTagId]) REFERENCES [dbo].[ContactTag] ([ContactTagId]),
    CONSTRAINT [FK_Contact_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_Contact]
ON [dbo].[Contact]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[ContactId],d.[Prefix],d.[FirstName],d.[LastName],d.[MiddleName],d.[Suffix],d.[ContactTitle],d.[WorkPhone],d.[WorkPhoneExtn],d.[MobilePhone],d.[AlternatePhone],d.[Fax],d.[Email],d.[WebsiteURL],d.[Notes],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[Tag],d.[IsDeleted],d.[ContactTagId],d.[Attention] FROM deleted d),
    i AS (SELECT i.[ContactId],i.[Prefix],i.[FirstName],i.[LastName],i.[MiddleName],i.[Suffix],i.[ContactTitle],i.[WorkPhone],i.[WorkPhoneExtn],i.[MobilePhone],i.[AlternatePhone],i.[Fax],i.[Email],i.[WebsiteURL],i.[Notes],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[Tag],i.[IsDeleted],i.[ContactTagId],i.[Attention] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.ContactId, d.ContactId ) AS ContactId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.ContactId IS NOT NULL AND d.ContactId IS NOT NULL THEN 'U'
                WHEN i.ContactId IS NOT NULL AND d.ContactId IS NULL     THEN 'I'
                WHEN i.ContactId IS NULL     AND d.ContactId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.ContactId, d.ContactId) AS ContactId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.ContactId = d.ContactId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.ContactId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'Contact'
                AND ign.ColumnName = N'ContactId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.ContactId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'Contact'
                AND ign.ColumnName = N'ContactId'
        )),
    merged AS (
        SELECT
            COALESCE(n.PKJson, o.PKJson)                AS PKJson,
            COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
            o.OldValue,
            n.NewValue,
            p.Action,
            n.ContactId
        FROM paired p
        LEFT JOIN oldv o
            ON o.ContactId = p.ContactId
        LEFT JOIN newv n
            ON n.ContactId = p.ContactId
            AND n.ColumnName = o.ColumnName
        UNION ALL
        SELECT
            n.PKJson,
            n.ColumnName,
            NULL AS OldValue,
            n.NewValue,
            p.Action,
            n.ContactId
        FROM paired p
        LEFT JOIN newv n
            ON n.ContactId = p.ContactId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.ContactId = p.ContactId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue , ReferenceId)
    SELECT
        N'dbo' AS SchemaName,
        N'Contact' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        m.OldValue,
        m.NewValue,
        m.ContactId
    FROM merged m  
    WHERE
        m.ColumnName <> 'ContactId' and (
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