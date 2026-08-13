CREATE TABLE [dbo].[StocklineManagementStructureDetails] (
    [MSDetailsId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleID]        INT           NOT NULL,
    [ReferenceID]     BIGINT        NOT NULL,
    [EntityMSID]      BIGINT        NOT NULL,
    [Level1Id]        BIGINT        NULL,
    [Level1Name]      VARCHAR (500) NULL,
    [Level2Id]        BIGINT        NULL,
    [Level2Name]      VARCHAR (500) NULL,
    [Level3Id]        BIGINT        NULL,
    [Level3Name]      VARCHAR (500) NULL,
    [Level4Id]        BIGINT        NULL,
    [Level4Name]      VARCHAR (500) NULL,
    [Level5Id]        BIGINT        NULL,
    [Level5Name]      VARCHAR (500) NULL,
    [Level6Id]        BIGINT        NULL,
    [Level6Name]      VARCHAR (500) NULL,
    [Level7Id]        BIGINT        NULL,
    [Level7Name]      VARCHAR (500) NULL,
    [Level8Id]        BIGINT        NULL,
    [Level8Name]      VARCHAR (500) NULL,
    [Level9Id]        BIGINT        NULL,
    [Level9Name]      VARCHAR (500) NULL,
    [Level10Id]       BIGINT        NULL,
    [Level10Name]     VARCHAR (500) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_StocklineManagmentStructureDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_StocklineManagmentStructureDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_StocklineManagmentStructureDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_StocklineManagmentStructureDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LastMSLevel]     VARCHAR (200) NULL,
    [AllMSlevels]     VARCHAR (MAX) NULL,
    CONSTRAINT [PK_StocklineManagmentStructureDetails] PRIMARY KEY CLUSTERED ([MSDetailsId] ASC)
);




GO

CREATE TRIGGER [dbo].[Trg_StocklineManagementStructureDetailsAudit]

   ON  [dbo].[StocklineManagementStructureDetails]

   AFTER INSERT,DELETE,UPDATE
AS

BEGIN

INSERT INTO StocklineManagementStructureDetailsAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END
GO
CREATE NONCLUSTERED INDEX [IX_SMSD_Report]
    ON [dbo].[StocklineManagementStructureDetails]([ModuleID] ASC, [ReferenceID] ASC)
    INCLUDE([EntityMSID], [Level1Id], [Level2Id], [Level3Id], [Level4Id], [Level5Id], [Level6Id], [Level7Id], [Level8Id], [Level9Id], [Level10Id], [Level1Name], [Level2Name], [Level3Name], [Level4Name], [Level5Name], [Level6Name], [Level7Name], [Level8Name], [Level9Name], [Level10Name]);


GO
CREATE NONCLUSTERED INDEX [IX_SLMSD_Module_Ref]
    ON [dbo].[StocklineManagementStructureDetails]([ModuleID] ASC, [ReferenceID] ASC)
    INCLUDE([EntityMSID], [Level1Id], [Level2Id], [Level3Id], [Level4Id], [Level5Id], [Level6Id], [Level7Id], [Level8Id], [Level9Id], [Level10Id], [Level1Name], [Level2Name], [Level3Name], [Level4Name], [Level5Name], [Level6Name], [Level7Name], [Level8Name], [Level9Name], [Level10Name]);


GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_StocklineManagementStructureDetails]
ON [dbo].[StocklineManagementStructureDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH
    d AS (SELECT d.[MSDetailsId],d.[ModuleID],d.[ReferenceID],d.[EntityMSID],d.[Level1Id],d.[Level1Name],d.[Level2Id],d.[Level2Name],d.[Level3Id],d.[Level3Name],d.[Level4Id],d.[Level4Name],d.[Level5Id],d.[Level5Name],d.[Level6Id],d.[Level6Name],d.[Level7Id],d.[Level7Name],d.[Level8Id],d.[Level8Name],d.[Level9Id],d.[Level9Name],d.[Level10Id],d.[Level10Name],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[LastMSLevel],d.[AllMSlevels] FROM deleted d),
    i AS (SELECT i.[MSDetailsId],i.[ModuleID],i.[ReferenceID],i.[EntityMSID],i.[Level1Id],i.[Level1Name],i.[Level2Id],i.[Level2Name],i.[Level3Id],i.[Level3Name],i.[Level4Id],i.[Level4Name],i.[Level5Id],i.[Level5Name],i.[Level6Id],i.[Level6Name],i.[Level7Id],i.[Level7Name],i.[Level8Id],i.[Level8Name],i.[Level9Id],i.[Level9Name],i.[Level10Id],i.[Level10Name],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[LastMSLevel],i.[AllMSlevels] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.MSDetailsId, d.MSDetailsId ) AS MSDetailsId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json,
            CASE
                WHEN i.MSDetailsId IS NOT NULL AND d.MSDetailsId IS NOT NULL THEN 'U'
                WHEN i.MSDetailsId IS NOT NULL AND d.MSDetailsId IS NULL     THEN 'I'
                WHEN i.MSDetailsId IS NULL     AND d.MSDetailsId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.MSDetailsId, d.MSDetailsId) AS MSDetailsId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.MSDetailsId = d.MSDetailsId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.MSDetailsId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'StocklineManagementStructureDetails'
                AND ign.ColumnName = N'MSDetailsId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.MSDetailsId,
            v.[key] AS ColumnName,
            v.value AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'StocklineManagementStructureDetails'
                AND ign.ColumnName = N'MSDetailsId'
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
            ON o.MSDetailsId = p.MSDetailsId
        LEFT JOIN newv n
            ON n.MSDetailsId = p.MSDetailsId
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
            ON n.MSDetailsId = p.MSDetailsId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.MSDetailsId = p.MSDetailsId
                AND o2.ColumnName    = n.ColumnName
        )
    ),
    ManagementStructureChanges AS
    (
        SELECT
            COALESCE(i.[MSDetailsId], d.[MSDetailsId]) AS [MSDetailsId],
            COALESCE(i.[ReferenceID], d.[ReferenceID]) AS [StockLineId],
            d.[LastMSLevel] AS [OldValue],
            i.[LastMSLevel] AS [NewValue],
            CASE
                WHEN i.[MSDetailsId] IS NOT NULL AND d.[MSDetailsId] IS NOT NULL THEN 'U'
                WHEN i.[MSDetailsId] IS NOT NULL AND d.[MSDetailsId] IS NULL THEN 'I'
                WHEN i.[MSDetailsId] IS NULL AND d.[MSDetailsId] IS NOT NULL THEN 'D'
            END AS [Action]
        FROM i
        FULL OUTER JOIN d ON d.[MSDetailsId] = i.[MSDetailsId]
        INNER JOIN [dbo].[Stockline] sl WITH(NOLOCK)
            ON sl.[StockLineId] = COALESCE(i.[ReferenceID], d.[ReferenceID])
           AND ISNULL(sl.[IsNonStock], 0) = 1
        WHERE COALESCE(i.[ModuleID], d.[ModuleID]) = 2
    )
    INSERT INTO [dbo].[AuditLog]
    (
        [SchemaName], [TableName], [PKJson], [ColumnName], [Action], [OldValue], [NewValue]
    )
    SELECT
        N'dbo' AS [SchemaName],
        N'StocklineManagementStructureDetails' AS [TableName],
        m.[PKJson],
        m.[ColumnName],
        m.[Action],
        m.[OldValue],
        m.[NewValue]
    FROM merged m
    WHERE (m.[Action] = 'U' AND
          (
              (m.[OldValue] IS NULL AND m.[NewValue] IS NOT NULL)
              OR (m.[OldValue] IS NOT NULL AND m.[NewValue] IS NULL)
              OR (m.[OldValue] <> m.[NewValue])
          ))
       OR (m.[Action] = 'I' AND m.[NewValue] IS NOT NULL)
       OR (m.[Action] = 'D' AND m.[OldValue] IS NOT NULL)

    UNION ALL

    SELECT
        N'dbo' AS [SchemaName],
        N'Stockline' AS [TableName],
        (SELECT msc.[StockLineId] AS [StockLineId] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS [PKJson],
        N'ManagementStructure' AS [ColumnName],
        msc.[Action],
        msc.[OldValue],
        msc.[NewValue]
    FROM ManagementStructureChanges msc
    WHERE (msc.[Action] = 'I' AND msc.[NewValue] IS NOT NULL)
       OR (msc.[Action] = 'D')
       OR (msc.[Action] = 'U' AND
          (
              (msc.[OldValue] IS NULL AND msc.[NewValue] IS NOT NULL)
              OR (msc.[OldValue] IS NOT NULL AND msc.[NewValue] IS NULL)
              OR (msc.[OldValue] <> msc.[NewValue])
          ));
END;