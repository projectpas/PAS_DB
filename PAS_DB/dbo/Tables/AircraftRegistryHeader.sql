CREATE TABLE [dbo].[AircraftRegistryHeader] (
    [AircraftRegistryId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [MakeTypeId]             BIGINT          NOT NULL,
    [MakeType]               VARCHAR (100)   NULL,
    [AircraftModelId]        BIGINT          NULL,
    [AircraftModel]          VARCHAR (100)   NULL,
    [AircraftSubModel]       VARCHAR (100)   NULL,
    [NumOfEngines]           INT             NULL,
    [TailNum]                VARCHAR (50)    NOT NULL,
    [SerialNum]              VARCHAR (100)   NULL,
    [ManufacturedDate]       DATETIME2 (7)   NULL,
    [PlaceInServiceDate]     DATETIME2 (7)   NULL,
    [TotalTSN]               DECIMAL (18, 2) NULL,
    [TotalCSN]               DECIMAL (18, 2) NULL,
    [Hobbs]                  DECIMAL (18, 2) NULL,
    [AircraftLocation]       VARCHAR (200)   NULL,
    [NextScheduled]          DATETIME2 (7)   NULL,
    [MEL]                    BIT             NULL,
    [AircraftStatusId]       BIGINT          NULL,
    [AircraftStatus]         VARCHAR (100)   NULL,
    [MaintenanceStatusId]    BIGINT          NULL,
    [MaintenanceStatus]      VARCHAR (100)   NULL,
    [Memo]                   VARCHAR (MAX)   NULL,
    [StockLineId]            BIGINT          NULL,
    [IsActive]               BIT             CONSTRAINT [DF_AircraftRegistry_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_AircraftRegistry_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_AircraftRegistry_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_AircraftRegistry_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [AircraftRegistryNumber] VARCHAR (30)    NULL,
    [LastMaintenanceDate]    DATETIME        NULL,
    [TotalTSNMM]             DECIMAL (18, 6) NULL,
    [TotalCSNMM]             DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_AircraftRegistry] PRIMARY KEY CLUSTERED ([AircraftRegistryId] ASC),
    CONSTRAINT [FK_AircraftRegistry_AircraftStatus] FOREIGN KEY ([AircraftStatusId]) REFERENCES [dbo].[AircraftStatus] ([AircraftStatusId]),
    CONSTRAINT [FK_AircraftRegistry_MaintenanceStatus] FOREIGN KEY ([MaintenanceStatusId]) REFERENCES [dbo].[MaintenanceStatus] ([MaintenanceStatusId]),
    CONSTRAINT [FK_AircraftRegistry_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO

CREATE     TRIGGER [dbo].[trg_Audit_dbo_AircraftRegistryHeader]
        ON [dbo].[AircraftRegistryHeader]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[AircraftRegistryId],d.[MakeTypeId],d.[MakeType],d.[AircraftModelId],d.[AircraftModel],d.[AircraftSubModel],d.[NumOfEngines],d.[TailNum],d.[SerialNum],d.[ManufacturedDate],d.[PlaceInServiceDate],d.[TotalTSN],d.[TotalCSN],d.[Hobbs],d.[AircraftLocation],d.[NextScheduled],d.[MEL],d.[AircraftStatusId],d.[AircraftStatus],d.[MaintenanceStatusId],d.[MaintenanceStatus],d.[IsActive],d.[IsDeleted],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate] FROM deleted d),
            i AS (SELECT i.[AircraftRegistryId],i.[MakeTypeId],i.[MakeType],i.[AircraftModelId],i.[AircraftModel],i.[AircraftSubModel],i.[NumOfEngines],i.[TailNum],i.[SerialNum],i.[ManufacturedDate],i.[PlaceInServiceDate],i.[TotalTSN],i.[TotalCSN],i.[Hobbs],i.[AircraftLocation],i.[NextScheduled],i.[MEL],i.[AircraftStatusId],i.[AircraftStatus],i.[MaintenanceStatusId],i.[MaintenanceStatus],i.[IsActive],i.[IsDeleted],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.AircraftRegistryId, d.AircraftRegistryId ) AS AircraftRegistryId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.AircraftRegistryId IS NOT NULL AND d.AircraftRegistryId IS NOT NULL THEN 'U'
                        WHEN i.AircraftRegistryId IS NOT NULL AND d.AircraftRegistryId IS NULL     THEN 'I'
                        WHEN i.AircraftRegistryId IS NULL     AND d.AircraftRegistryId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.AircraftRegistryId, d.AircraftRegistryId) AS AircraftRegistryId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.AircraftRegistryId = d.AircraftRegistryId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.AircraftRegistryId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'AircraftRegistryHeader'
                      AND ign.ColumnName = N'AircraftRegistryId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.AircraftRegistryId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'AircraftRegistryHeader'
                      AND ign.ColumnName = N'AircraftRegistryId'
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
                    ON o.AircraftRegistryId = p.AircraftRegistryId
                LEFT JOIN newv n
                    ON n.AircraftRegistryId = p.AircraftRegistryId
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
                    ON n.AircraftRegistryId = p.AircraftRegistryId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.AircraftRegistryId = p.AircraftRegistryId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'AircraftRegistryHeader' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                m.ColumnName <> 'AircraftRegistryId' and (
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