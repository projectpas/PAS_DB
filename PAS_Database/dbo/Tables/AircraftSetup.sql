CREATE TABLE [dbo].[AircraftSetup] (
    [AircraftSetupId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [MaintenanceStatusId]  BIGINT        NOT NULL,
    [AircraftStatusId]     BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CurrencyId]           INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [DF_AircraftSetup_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [DF_AircraftSetup_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [DF_AircraftSetup_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [DF_AircraftSetup_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PurchaseUOMId]        BIGINT        NULL,
    [StockUOMId]           BIGINT        NULL,
    [ConsumeUOMId]         BIGINT        NULL,
    [PurchaseCurrencyId]   INT           NULL,
    [SalesCurrencyId]      INT           NULL,
    [ItemClassificationId] BIGINT        NULL,
    [InventoryGLSettingId] BIGINT        NULL,
    [InventoryGLAccId]     BIGINT        NULL,
    [UOMId]                BIGINT        NULL,
    [RedIndicator]         INT           NULL,
    [YellowIndicator]      INT           NULL,
    [GreenIndicator]       INT           NULL,
    [ItemgroupId]          BIGINT        NULL,
    [SiteId]               BIGINT        NULL,
    [WorkScopeId]          BIGINT        NULL,
    [ConditionId]          BIGINT        NULL,
    [IsAllowWorksheets]    BIT           NULL,
    [ColorIndicator1Code]  VARCHAR (20)  NULL,
    [ColorIndicator1Value] INT           NULL,
    [ColorIndicator2Code]  VARCHAR (20)  NULL,
    [ColorIndicator2Value] INT           NULL,
    [ColorIndicator3Code]  VARCHAR (20)  NULL,
    [ColorIndicator3Value] INT           NULL,
    CONSTRAINT [PK_AircraftSetup] PRIMARY KEY CLUSTERED ([AircraftSetupId] ASC)
);


GO
     CREATE   TRIGGER [dbo].[trg_Audit_dbo_AircraftSetup]
        ON [dbo].[AircraftSetup]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[AircraftSetupId],d.[MaintenanceStatusId],d.[AircraftStatusId],d.[MasterCompanyId],d.[CurrencyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[PurchaseUOMId],d.[StockUOMId],d.[ConsumeUOMId],d.[PurchaseCurrencyId],d.[SalesCurrencyId],d.[ItemClassificationId],d.[InventoryGLSettingId],d.[InventoryGLAccId],d.[UOMId],d.[RedIndicator],d.[YellowIndicator],d.[GreenIndicator],d.[ItemgroupId],d.[SiteId],d.[WorkScopeId],d.[ConditionId],d.[IsAllowWorksheets],d.[ColorIndicator1Code],d.[ColorIndicator1Value],d.[ColorIndicator2Code],d.[ColorIndicator2Value],d.[ColorIndicator3Code],d.[ColorIndicator3Value] FROM deleted d),
            i AS (SELECT i.[AircraftSetupId],i.[MaintenanceStatusId],i.[AircraftStatusId],i.[MasterCompanyId],i.[CurrencyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[PurchaseUOMId],i.[StockUOMId],i.[ConsumeUOMId],i.[PurchaseCurrencyId],i.[SalesCurrencyId],i.[ItemClassificationId],i.[InventoryGLSettingId],i.[InventoryGLAccId],i.[UOMId],i.[RedIndicator],i.[YellowIndicator],i.[GreenIndicator],i.[ItemgroupId],i.[SiteId],i.[WorkScopeId],i.[ConditionId],i.[IsAllowWorksheets],i.[ColorIndicator1Code],i.[ColorIndicator1Value],i.[ColorIndicator2Code],i.[ColorIndicator2Value],i.[ColorIndicator3Code],i.[ColorIndicator3Value] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.AircraftSetupId, d.AircraftSetupId ) AS AircraftSetupId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.AircraftSetupId IS NOT NULL AND d.AircraftSetupId IS NOT NULL THEN 'U'
                        WHEN i.AircraftSetupId IS NOT NULL AND d.AircraftSetupId IS NULL     THEN 'I'
                        WHEN i.AircraftSetupId IS NULL     AND d.AircraftSetupId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.AircraftSetupId, d.AircraftSetupId) AS AircraftSetupId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.AircraftSetupId = d.AircraftSetupId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.AircraftSetupId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'AircraftSetup'
                      AND ign.ColumnName = N'AircraftSetupId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.AircraftSetupId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'AircraftSetup'
                      AND ign.ColumnName = N'AircraftSetupId'
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
                    ON o.AircraftSetupId = p.AircraftSetupId
                LEFT JOIN newv n
                    ON n.AircraftSetupId = p.AircraftSetupId
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
                    ON n.AircraftSetupId = p.AircraftSetupId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.AircraftSetupId = p.AircraftSetupId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'AircraftSetup' AS TableName,
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
