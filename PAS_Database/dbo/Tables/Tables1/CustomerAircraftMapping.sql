CREATE TABLE [dbo].[CustomerAircraftMapping] (
    [CustomerAircraftMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                BIGINT        NOT NULL,
    [AircraftTypeId]            INT           NOT NULL,
    [AircraftModelId]           BIGINT        NULL,
    [DashNumberId]              BIGINT        NULL,
    [AircraftType]              VARCHAR (250) NOT NULL,
    [AircraftModel]             VARCHAR (250) NOT NULL,
    [DashNumber]                VARCHAR (250) NOT NULL,
    [Inventory]                 INT           CONSTRAINT [DF_CustomerAircraftMapping_Inventory] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_CustomerAircraftMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_CustomerAircraftMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [D_CAM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [CustomerAircraftMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CACMapping] PRIMARY KEY CLUSTERED ([CustomerAircraftMappingId] ASC),
    CONSTRAINT [FK_CustomerAircraftMapping_AircraftDashNumber] FOREIGN KEY ([DashNumberId]) REFERENCES [dbo].[AircraftDashNumber] ([DashNumberId]),
    CONSTRAINT [FK_CustomerAircraftMapping_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_CustomerAircraftMapping_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_CustomerAircraftMapping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerAircraftMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [CustomerAircraftMappingConstrain] UNIQUE NONCLUSTERED ([CustomerId] ASC, [AircraftTypeId] ASC, [AircraftModelId] ASC, [DashNumberId] ASC, [MasterCompanyId] ASC)
);




GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_CustomerAircraftMapping]
ON [dbo].[CustomerAircraftMapping]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[CustomerAircraftMappingId],d.[CustomerId],d.[AircraftTypeId],d.[AircraftModelId],d.[DashNumberId],d.[AircraftType],d.[AircraftModel],d.[DashNumber],d.[Inventory],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted] FROM deleted d),
    i AS (SELECT i.[CustomerAircraftMappingId],i.[CustomerId],i.[AircraftTypeId],i.[AircraftModelId],i.[DashNumberId],i.[AircraftType],i.[AircraftModel],i.[DashNumber],i.[Inventory],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.CustomerAircraftMappingId, d.CustomerAircraftMappingId ) AS CustomerAircraftMappingId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.CustomerAircraftMappingId IS NOT NULL AND d.CustomerAircraftMappingId IS NOT NULL THEN 'U'
                WHEN i.CustomerAircraftMappingId IS NOT NULL AND d.CustomerAircraftMappingId IS NULL     THEN 'I'
                WHEN i.CustomerAircraftMappingId IS NULL     AND d.CustomerAircraftMappingId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.CustomerAircraftMappingId, d.CustomerAircraftMappingId) AS CustomerAircraftMappingId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.CustomerAircraftMappingId = d.CustomerAircraftMappingId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.CustomerAircraftMappingId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerAircraftMapping'
                AND ign.ColumnName = N'CustomerAircraftMappingId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.CustomerAircraftMappingId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'CustomerAircraftMapping'
                AND ign.ColumnName = N'CustomerAircraftMappingId'
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
            ON o.CustomerAircraftMappingId = p.CustomerAircraftMappingId
        LEFT JOIN newv n
            ON n.CustomerAircraftMappingId = p.CustomerAircraftMappingId
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
            ON n.CustomerAircraftMappingId = p.CustomerAircraftMappingId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.CustomerAircraftMappingId = p.CustomerAircraftMappingId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'CustomerAircraftMapping' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        m.OldValue,
        m.NewValue
    FROM merged m
    WHERE
        m.ColumnName <> 'CustomerAircraftMappingId' and (
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