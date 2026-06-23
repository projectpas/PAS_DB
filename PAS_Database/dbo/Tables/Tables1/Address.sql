CREATE TABLE [dbo].[Address] (
    [AddressId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [POBox]           VARCHAR (30)    NULL,
    [Line1]           VARCHAR (50)    NOT NULL,
    [Line2]           VARCHAR (50)    NULL,
    [Line3]           VARCHAR (50)    NULL,
    [City]            VARCHAR (50)    NOT NULL,
    [StateOrProvince] VARCHAR (50)    NOT NULL,
    [PostalCode]      VARCHAR (20)    NOT NULL,
    [CountryId]       SMALLINT        NOT NULL,
    [Latitude]        DECIMAL (12, 9) NULL,
    [Longitude]       DECIMAL (12, 9) NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Address_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [DF_Address_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [DF_Address_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [DF_Address_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Address] PRIMARY KEY CLUSTERED ([AddressId] ASC),
    CONSTRAINT [FK_Address_Countries] FOREIGN KEY ([CountryId]) REFERENCES [dbo].[Countries] ([countries_id]),
    CONSTRAINT [FK_Address_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




CREATE TRIGGER [dbo].[Trg_AddressAudit] ON [dbo].[Address]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

 INSERT INTO [dbo].[AddressAudit]  

 SELECT * FROM INSERTED  

  

 SET NOCOUNT ON;  

  

END
GO

     
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_Address]
        ON [dbo].[Address]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[AddressId],d.[POBox],d.[Line1],d.[Line2],d.[Line3],d.[City],d.[StateOrProvince],d.[PostalCode],d.[CountryId],d.[Latitude],d.[Longitude],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
            i AS (SELECT i.[AddressId],i.[POBox],i.[Line1],i.[Line2],i.[Line3],i.[City],i.[StateOrProvince],i.[PostalCode],i.[CountryId],i.[Latitude],i.[Longitude],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.AddressId, d.AddressId ) AS AddressId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.AddressId IS NOT NULL AND d.AddressId IS NOT NULL THEN 'U'
                        WHEN i.AddressId IS NOT NULL AND d.AddressId IS NULL     THEN 'I'
                        WHEN i.AddressId IS NULL     AND d.AddressId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.AddressId, d.AddressId) AS AddressId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.AddressId = d.AddressId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.AddressId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Address'
                      AND ign.ColumnName = N'AddressId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.AddressId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Address'
                      AND ign.ColumnName = N'AddressId'
                )),
            merged AS (
                SELECT
                    COALESCE(n.PKJson, o.PKJson)                AS PKJson,
                    COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
                    o.OldValue,
                    n.NewValue,
                    p.Action,
                    n.AddressId
                FROM paired p
                LEFT JOIN oldv o
                    ON o.AddressId = p.AddressId
                LEFT JOIN newv n
                    ON n.AddressId = p.AddressId
                   AND n.ColumnName = o.ColumnName
                UNION ALL
                SELECT
                    n.PKJson,
                    n.ColumnName,
                    NULL AS OldValue,
                    n.NewValue,
                    p.Action,
                    n.AddressId
                FROM paired p
                LEFT JOIN newv n
                    ON n.AddressId = p.AddressId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.AddressId = p.AddressId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue, ReferenceId)
            SELECT
                N'dbo' AS SchemaName,
                N'Address' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'CountryId' THEN ctOld.countries_name
                    ELSE m.OldValue
                END AS OldValue,  
                CASE 
                    WHEN m.ColumnName = 'CountryId' THEN ctNew.countries_name
                    ELSE m.NewValue
                END AS NewValue,
                m.AddressId
            FROM merged m
            LEFT JOIN DBO.Countries ctold WITH (NOLOCK) ON m.ColumnName = 'CountryId'AND TRY_CAST(m.OldValue AS bigint)  = ctold.countries_id
            LEFT JOIN DBO.Countries ctNew WITH (NOLOCK) ON m.ColumnName = 'CountryId'AND TRY_CAST(m.NewValue AS bigint)  = ctNew.countries_id
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