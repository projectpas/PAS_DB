CREATE TABLE [dbo].[AircraftCycleTimeMappings] (
    [AircraftCycleTimeMappingsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ModuleId]                    BIGINT          NOT NULL,
    [RefrenceId]                  BIGINT          NOT NULL,
    [CycleDate]                   DATETIME2 (7)   NULL,
    [Hours]                       DECIMAL (18, 6) NULL,
    [CurruntHours]                DECIMAL (18, 6) NULL,
    [CumulativeHours]             DECIMAL (18, 6) NULL,
    [Cycles]                      DECIMAL (18, 6) NULL,
    [CurruntCycles]               DECIMAL (18, 6) NULL,
    [CumulativeCycles]            DECIMAL (18, 6) NULL,
    [Memo]                        NVARCHAR (MAX)  NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   NOT NULL,
    [IsActive]                    BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             DEFAULT ((0)) NOT NULL,
    [Minutes]                     DECIMAL (18, 6) NULL,
    [CurruntMinutes]              DECIMAL (18, 6) NULL,
    [CumulativeMinutes]           DECIMAL (18, 6) NULL,
    [CyclesMinutes]               DECIMAL (18, 6) NULL,
    [CurruntCyclesMinutes]        DECIMAL (18, 6) NULL,
    [CumulativeCyclesMinutes]     DECIMAL (18, 6) NULL,
    PRIMARY KEY CLUSTERED ([AircraftCycleTimeMappingsId] ASC),
    CONSTRAINT [FK_AircraftCycleTimeMappings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_AircraftCycleTimeMappings] 
ON [dbo].[AircraftCycleTimeMappings] 
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH 
    d AS (
        SELECT d.[AircraftCycleTimeMappingsId],
               d.[ModuleId],
               d.[RefrenceId],
               d.[CycleDate],
               d.[Hours],
               d.[CurruntHours],
               d.[CumulativeHours],
               d.[Cycles],
               d.[CurruntCycles],
               d.[CumulativeCycles],
               d.[Memo],
               d.[MasterCompanyId],
               d.[CreatedBy],
               d.[UpdatedBy],
               d.[CreatedDate],
               d.[UpdatedDate],
               d.[IsActive],
               d.[IsDeleted],
               d.[Minutes],
               d.[CurruntMinutes],
               d.[CumulativeMinutes],
               d.[CyclesMinutes],
               d.[CurruntCyclesMinutes],
               d.[CumulativeCyclesMinutes]
        FROM deleted d
    ),
    i AS (
        SELECT i.[AircraftCycleTimeMappingsId],
               i.[ModuleId],
               i.[RefrenceId],
               i.[CycleDate],
               i.[Hours],
               i.[CurruntHours],
               i.[CumulativeHours],
               i.[Cycles],
               i.[CurruntCycles],
               i.[CumulativeCycles],
               i.[Memo],
               i.[MasterCompanyId],
               i.[CreatedBy],
               i.[UpdatedBy],
               i.[CreatedDate],
               i.[UpdatedDate],
               i.[IsActive],
               i.[IsDeleted],
               i.[Minutes],
               i.[CurruntMinutes],
               i.[CumulativeMinutes],
               i.[CyclesMinutes],
               i.[CurruntCyclesMinutes],
               i.[CumulativeCyclesMinutes]
        FROM inserted i
    ),
    paired AS (
        SELECT COALESCE(i.[AircraftCycleTimeMappingsId], d.[AircraftCycleTimeMappingsId]) AS [AircraftCycleTimeMappingsId],
               (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
               (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json,
               CASE
                   WHEN i.[AircraftCycleTimeMappingsId] IS NOT NULL AND d.[AircraftCycleTimeMappingsId] IS NOT NULL THEN 'U'
                   WHEN i.[AircraftCycleTimeMappingsId] IS NOT NULL AND d.[AircraftCycleTimeMappingsId] IS NULL THEN 'I'
                   WHEN i.[AircraftCycleTimeMappingsId] IS NULL AND d.[AircraftCycleTimeMappingsId] IS NOT NULL THEN 'D'
               END AS action,
               (SELECT COALESCE(i.[AircraftCycleTimeMappingsId], d.[AircraftCycleTimeMappingsId]) AS [AircraftCycleTimeMappingsId] FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS pkjson
        FROM d
        FULL OUTER JOIN i ON i.[AircraftCycleTimeMappingsId] = d.[AircraftCycleTimeMappingsId]
    ),
    oldv AS (
        SELECT p.pkjson,
               p.[AircraftCycleTimeMappingsId],
               v.[key] AS columnname,
               v.value AS oldvalue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH (NOLOCK)
            WHERE ign.SchemaName = N'dbo'
            AND ign.TableName = N'AircraftCycleTimeMappings'
            AND ign.ColumnName = N'AircraftCycleTimeMappingsId'
        )
    ),
    newv AS (
        SELECT p.pkjson,
               p.[AircraftCycleTimeMappingsId],
               v.[key] AS columnname,
               v.value AS newvalue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH (NOLOCK)
            WHERE ign.SchemaName = N'dbo'
            AND ign.TableName = N'AircraftCycleTimeMappings'
            AND ign.ColumnName = N'AircraftCycleTimeMappingsId'
        )
    ),
    merged AS (
        SELECT COALESCE(n.pkjson, o.pkjson) AS pkjson,
               COALESCE(n.columnname, o.columnname) AS columnname,
               o.oldvalue,
               n.newvalue,
               p.action
        FROM paired p
        LEFT JOIN oldv o ON o.[AircraftCycleTimeMappingsId] = p.[AircraftCycleTimeMappingsId]
        LEFT JOIN newv n ON n.[AircraftCycleTimeMappingsId] = p.[AircraftCycleTimeMappingsId]
                         AND n.columnname = o.columnname
        UNION ALL
        SELECT n.pkjson,
               n.columnname,
               NULL AS oldvalue,
               n.newvalue,
               p.action
        FROM paired p
        LEFT JOIN newv n ON n.[AircraftCycleTimeMappingsId] = p.[AircraftCycleTimeMappingsId]
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.[AircraftCycleTimeMappingsId] = p.[AircraftCycleTimeMappingsId]
            AND o2.columnname = n.columnname
        )
    ),
    hourminutes_changes AS (
        SELECT pkjson,
               'HoursMinutes' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'Hours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'Minutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'Hours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'Minutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'Hours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'Minutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'Hours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'Minutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('Hours', 'Minutes')
        GROUP BY pkjson, action
    ),
    currunthoursminutes_changes AS (
        SELECT pkjson,
                'CurruntHoursMinutes' AS columnname,
                CASE
                    WHEN MIN(CASE WHEN columnname = 'CurruntHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'CurruntMinutes' THEN oldvalue END) IS NULL
                    THEN NULL
                    ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CurruntHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                                CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CurruntMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
                END AS oldvalue,
                CASE
                    WHEN MIN(CASE WHEN columnname = 'CurruntHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'CurruntMinutes' THEN newvalue END) IS NULL
                    THEN NULL
                    ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CurruntHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                                CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CurruntMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
                END AS newvalue,
                action
        FROM merged
        WHERE columnname IN ('CurruntHours', 'CurruntMinutes')
        GROUP BY pkjson, action
    ),
    cumulativehoursminutes_changes AS (
        SELECT pkjson,
                'CumulativeHoursMinutes' AS columnname,
                CASE
                    WHEN MIN(CASE WHEN columnname = 'CumulativeHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'CumulativeMinutes' THEN oldvalue END) IS NULL
                    THEN NULL
                    ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CumulativeHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                                CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CumulativeMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
                END AS oldvalue,
                CASE
                    WHEN MIN(CASE WHEN columnname = 'CumulativeHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'CumulativeMinutes' THEN newvalue END) IS NULL
                    THEN NULL
                    ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CumulativeHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                                CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'CumulativeMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
                END AS newvalue,
                action
        FROM merged
        WHERE columnname IN ('CumulativeHours', 'CumulativeMinutes')
        GROUP BY pkjson, action
    ),    
    other_changes AS (
        SELECT pkjson,
               columnname,
               oldvalue,
               newvalue,
               action
        FROM merged
        WHERE columnname NOT IN ('Hours', 'Minutes', 'CurruntHours', 'CurruntMinutes', 'AircraftCycleTimeMappingsId')
    ),
    all_changes AS (
        SELECT * FROM hourminutes_changes
        UNION ALL
        SELECT * FROM currunthoursminutes_changes
        UNION ALL
        SELECT * FROM cumulativehoursminutes_changes
        UNION ALL
        SELECT * FROM other_changes
    )
    INSERT INTO dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT N'dbo' AS SchemaName,
           N'AircraftCycleTimeMappings' AS TableName,
           a.pkjson,
           a.columnname,
           a.action,
           a.oldvalue,
           a.newvalue
    FROM all_changes a
    WHERE ((a.action = 'U'
            AND ((a.oldvalue IS NULL AND a.newvalue IS NOT NULL)
                 OR (a.oldvalue IS NOT NULL AND a.newvalue IS NULL)
                 OR (a.oldvalue <> a.newvalue)))
           OR (a.action = 'I' AND a.newvalue IS NOT NULL)
           OR (a.action = 'D' AND a.oldvalue IS NOT NULL));
END;