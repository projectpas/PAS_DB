CREATE TABLE [dbo].[Publication] (
    [PublicationRecordId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [PublicationId]          VARCHAR (100)  NOT NULL,
    [Description]            VARCHAR (4000) NOT NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  NOT NULL,
    [IsActive]               BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            DEFAULT ((0)) NOT NULL,
    [EntryDate]              DATETIME2 (7)  NULL,
    [ASD]                    VARCHAR (100)  NULL,
    [revisionDate]           DATETIME2 (7)  NULL,
    [VerifiedDate]           DATETIME2 (7)  NULL,
    [NextReviewDate]         DATETIME2 (7)  NULL,
    [PublicationTypeId]      BIGINT         NOT NULL,
    [EmployeeId]             BIGINT         NULL,
    [ExpirationDate]         DATETIME       NULL,
    [Sequence]               INT            NULL,
    [RevisionNum]            VARCHAR (100)  NULL,
    [VerifiedBy]             BIGINT         NULL,
    [VerifiedStatus]         BIT            NOT NULL,
    [LocationId]             BIGINT         NOT NULL,
    [PublishedById]          INT            NULL,
    [PublishedByRefId]       BIGINT         NULL,
    [PublishedByOthers]      VARCHAR (100)  NULL,
    [ManagementStructureIds] VARCHAR (50)   NULL,
    [URL]                    NVARCHAR (500) NULL,
    [Fleet]                  VARCHAR (50)   NULL,
    CONSTRAINT [PK_Publication] PRIMARY KEY CLUSTERED ([PublicationRecordId] ASC),
    CONSTRAINT [FK_Publication_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_Publication_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Publication_PublicationType] FOREIGN KEY ([PublicationTypeId]) REFERENCES [dbo].[PublicationType] ([PublicationTypeId]),
    CONSTRAINT [FK_PublicationPublication_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_PublicationPublication_PublishedById] FOREIGN KEY ([PublishedById]) REFERENCES [dbo].[Module] ([ModuleId])
);
















GO

     
     CREATE     TRIGGER [dbo].[trg_Audit_dbo_Publication]
        ON [dbo].[Publication]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[PublicationRecordId],d.[PublicationId],d.[Description],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[EntryDate],d.[ASD],d.[revisionDate],d.[VerifiedDate],d.[NextReviewDate],d.[PublicationTypeId],d.[EmployeeId],d.[ExpirationDate],d.[Sequence],d.[RevisionNum],d.[VerifiedBy],d.[VerifiedStatus],d.[LocationId],d.[PublishedById],d.[PublishedByRefId],d.[PublishedByOthers],d.[ManagementStructureIds],d.[URL],d.[Fleet] FROM deleted d),
            i AS (SELECT i.[PublicationRecordId],i.[PublicationId],i.[Description],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[EntryDate],i.[ASD],i.[revisionDate],i.[VerifiedDate],i.[NextReviewDate],i.[PublicationTypeId],i.[EmployeeId],i.[ExpirationDate],i.[Sequence],i.[RevisionNum],i.[VerifiedBy],i.[VerifiedStatus],i.[LocationId],i.[PublishedById],i.[PublishedByRefId],i.[PublishedByOthers],i.[ManagementStructureIds],i.[URL],i.[Fleet] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.PublicationRecordId, d.PublicationRecordId ) AS PublicationRecordId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.PublicationRecordId IS NOT NULL AND d.PublicationRecordId IS NOT NULL THEN 'U'
                        WHEN i.PublicationRecordId IS NOT NULL AND d.PublicationRecordId IS NULL     THEN 'I'
                        WHEN i.PublicationRecordId IS NULL     AND d.PublicationRecordId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.PublicationRecordId, d.PublicationRecordId) AS PublicationRecordId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.PublicationRecordId = d.PublicationRecordId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.PublicationRecordId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Publication'
                      AND ign.ColumnName = N'PublicationRecordId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.PublicationRecordId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Publication'
                      AND ign.ColumnName = N'PublicationRecordId'
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
                    ON o.PublicationRecordId = p.PublicationRecordId
                LEFT JOIN newv n
                    ON n.PublicationRecordId = p.PublicationRecordId
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
                    ON n.PublicationRecordId = p.PublicationRecordId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.PublicationRecordId = p.PublicationRecordId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'Publication' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                CASE             
                    WHEN m.ColumnName = 'PublishedById' THEN pemp.ModuleName
                    WHEN m.ColumnName = 'LocationId' THEN loc.Name
                    WHEN m.ColumnName = 'VerifiedBy' THEN LTRIM(RTRIM(ISNULL(vb.FirstName,'') + ' ' + ISNULL(vb.LastName,'')))
                    WHEN m.ColumnName = 'PublicationTypeId' THEN ptNew.Name
                ELSE m.OldValue
                END AS OldValue,        
                CASE 
                    WHEN m.ColumnName = 'PublishedById' THEN pempNew.ModuleName
                    WHEN m.ColumnName = 'LocationId' THEN locNew.Name
                    WHEN m.ColumnName = 'VerifiedBy' THEN LTRIM(RTRIM(ISNULL(vbNew.FirstName,'') + ' ' + ISNULL(vbNew.LastName,'')))
                    WHEN m.ColumnName = 'PublicationTypeId' THEN ptNew.Name
                    ELSE m.NewValue
                END AS NewValue
                FROM merged m
                LEFT JOIN DBO.PublicationType pt WITH (NOLOCK) ON m.ColumnName = 'PublicationTypeId' AND TRY_CAST(m.OldValue AS bigint)  = pt.PublicationTypeId
                LEFT JOIN DBO.PublicationType ptNew WITH (NOLOCK) ON m.ColumnName = 'PublicationTypeId' AND TRY_CAST(m.NewValue AS bigint)  = ptNew.PublicationTypeId
                LEFT JOIN DBO.Module pemp WITH (NOLOCK) ON m.ColumnName = 'PublishedById' AND TRY_CAST(m.OldValue AS bigint)  =  pemp.ModuleId
                LEFT JOIN DBO.Module pempNew WITH (NOLOCK) ON m.ColumnName = 'PublishedById' AND TRY_CAST(m.NewValue  AS bigint)  =  pempNew.ModuleId
                LEFT JOIN DBO.Location loc WITH (NOLOCK) ON m.ColumnName = 'LocationId' AND TRY_CAST(m.OldValue AS bigint) = loc.LocationId
                LEFT JOIN DBO.Location locNew WITH (NOLOCK) ON m.ColumnName = 'LocationId' AND TRY_CAST(m.NewValue  AS bigint) = locNew.LocationId
                LEFT JOIN DBO.Employee vb WITH (NOLOCK) ON m.ColumnName = 'VerifiedBy' AND TRY_CAST(m.OldValue AS bigint) = vb.EmployeeId
                LEFT JOIN DBO.Employee vbNew WITH (NOLOCK) ON m.ColumnName = 'VerifiedBy' AND TRY_CAST(m.NewValue  AS bigint) = vbNew.EmployeeId

            WHERE
            m.ColumnName <> 'PublicationRecordId' and (
                (m.Action = 'U' AND (
                     (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                  OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                  OR (m.OldValue <> m.NewValue)
                )
                OR
                (m.Action = 'I' AND m.NewValue IS NOT NULL)
                OR
                (m.Action = 'D' AND m.OldValue IS NOT NULL)));
        END;