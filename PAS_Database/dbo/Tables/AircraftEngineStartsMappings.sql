CREATE TABLE [dbo].[AircraftEngineStartsMappings] (
    [AircraftEngineStartsMappingsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AircraftCycleTimeMappingsId]    BIGINT          NULL,
    [EngineName]                     VARCHAR (50)    NULL,
    [Hours]                          DECIMAL (18, 6) NULL,
    [CurruntHours]                   DECIMAL (18, 6) NULL,
    [CumulativeHours]                DECIMAL (18, 6) NULL,
    [Starts]                         INT             NULL,
    [CurruntStarts]                  INT             NULL,
    [CumulativeStarts]               INT             NULL,
    [Memo]                           NVARCHAR (MAX)  NULL,
    [MasterCompanyId]                INT             NOT NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   NOT NULL,
    [IsActive]                       BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT             DEFAULT ((0)) NOT NULL,
    [Minutes]                        DECIMAL (18, 6) NULL,
    [CurruntMinutes]                 DECIMAL (18, 6) NULL,
    [CumulativeMinutes]              DECIMAL (18, 6) NULL,
    PRIMARY KEY CLUSTERED ([AircraftEngineStartsMappingsId] ASC),
    CONSTRAINT [FK_AircraftEngineStartsMappings_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);






GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_AircraftEngineStartsMappings] 
ON [dbo].[AircraftEngineStartsMappings]
AFTER INSERT, UPDATE, DELETE 
AS 
BEGIN 
    SET NOCOUNT ON;
    WITH d AS (
        SELECT d.[AircraftEngineStartsMappingsId],
                d.[AircraftCycleTimeMappingsId],
                d.[EngineName],
                d.[Hours] AS EngineAddHours,
                d.[CurruntHours] AS EngineCurrentHours,
                d.[CumulativeHours] AS EngineUpdatedHours,
                d.[Starts] AS EngineAddStarts,
                d.[CurruntStarts] AS EngineCurrentStarts,
                d.[CumulativeStarts] AS EngineUpdatedStarts,
                d.[Memo] AS EngineMemo,
                d.[MasterCompanyId] AS EngineMasterCompanyId,
                d.[CreatedBy] AS EngineCreatedBy,
                d.[UpdatedBy] AS EngineUpdatedBy,
                d.[CreatedDate] AS EngineCreatedDate,
                d.[UpdatedDate] AS EngineUpdatedDate,
                d.[IsActive] AS EngineIsActive,
                d.[IsDeleted] AS EngineIsDeleted,
                d.[Minutes] AS EngineAddMinutes,
                d.[CurruntMinutes] AS EngineCurrentMinutes,
                d.[CumulativeMinutes] AS EngineUpdatedMinutes
        FROM   deleted d
    ), 
    i AS (
        SELECT i.[AircraftEngineStartsMappingsId],
                i.[AircraftCycleTimeMappingsId],
                i.[EngineName],
                i.[Hours] AS EngineAddHours,
                i.[CurruntHours] AS EngineCurrentHours,
                i.[CumulativeHours] AS EngineUpdatedHours,
                i.[Starts] AS EngineAddStarts,
                i.[CurruntStarts] AS EngineCurrentStarts,
                i.[CumulativeStarts] AS EngineUpdatedStarts,
                i.[Memo] AS EngineMemo,
                i.[MasterCompanyId] AS EngineMasterCompanyId,
                i.[CreatedBy] AS EngineCreatedBy,
                i.[UpdatedBy] AS EngineUpdatedBy,
                i.[CreatedDate] AS EngineCreatedDate,
                i.[UpdatedDate] AS EngineUpdatedDate,
                i.[IsActive] AS EngineIsActive,
                i.[IsDeleted] AS EngineIsDeleted,
                i.[Minutes] AS EngineAddMinutes,
                i.[CurruntMinutes] AS EngineCurrentMinutes,
                i.[CumulativeMinutes] AS EngineUpdatedMinutes
        FROM   inserted i
    ), 
    paired AS (
        SELECT COALESCE(i.aircraftenginestartsmappingsid, d.aircraftenginestartsmappingsid) AS aircraftenginestartsmappingsid,
                (SELECT d.* FOR json path, without_array_wrapper) AS old_row_json,
                (SELECT i.* FOR json path, without_array_wrapper) AS new_row_json,
                CASE
                    WHEN i.aircraftenginestartsmappingsid IS NOT NULL
                        AND d.aircraftenginestartsmappingsid IS NOT NULL THEN 'U'
                    WHEN i.aircraftenginestartsmappingsid IS NOT NULL
                        AND d.aircraftenginestartsmappingsid IS NULL THEN 'I'
                    WHEN i.aircraftenginestartsmappingsid IS NULL
                        AND d.aircraftenginestartsmappingsid IS NOT NULL THEN 'D'
                END AS action,
                (SELECT COALESCE(i.aircraftenginestartsmappingsid, d.aircraftenginestartsmappingsid) AS aircraftenginestartsmappingsid FOR json path, without_array_wrapper) AS pkjson
        FROM   d
        FULL OUTER JOIN i
            ON i.aircraftenginestartsmappingsid = d.aircraftenginestartsmappingsid
    ), 
    oldv AS (
        SELECT p.pkjson,
                p.aircraftenginestartsmappingsid,
                v.[key] AS columnname,
                v.value AS oldvalue
        FROM   paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE  NOT EXISTS (
                    SELECT 1
                    FROM   dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE  ign.SchemaName = N'dbo'
                            AND ign.TableName = N'AircraftEngineStartsMappings'
                            AND ign.ColumnName = N'AircraftEngineStartsMappingsId'
                )
    ), 
    newv AS (
        SELECT p.pkjson,
                p.aircraftenginestartsmappingsid,
                v.[key] AS columnname,
                v.value AS newvalue
        FROM   paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE  NOT EXISTS (
                    SELECT 1
                    FROM   dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE  ign.SchemaName = N'dbo'
                            AND ign.TableName = N'AircraftEngineStartsMappings'
                            AND ign.ColumnName = N'AircraftEngineStartsMappingsId'
                )
    ), 
    merged AS (
        SELECT COALESCE(n.pkjson, o.pkjson) AS pkjson,
                COALESCE(n.columnname, o.columnname) AS columnname,
                o.oldvalue,
                n.newvalue,
                p.action
        FROM   paired p
        LEFT JOIN oldv o
            ON o.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
        LEFT JOIN newv n
            ON n.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
                AND n.columnname = o.columnname
        UNION ALL
        SELECT n.pkjson,
                n.columnname,
                NULL AS oldvalue,
                n.newvalue,
                p.action
        FROM   paired p
        LEFT JOIN newv n
            ON n.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
        WHERE  NOT EXISTS (
                    SELECT 1
                    FROM   oldv o2
                    WHERE  o2.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
                            AND o2.columnname = n.columnname
                )
    ),
    engineaddhoursminutes_changes AS (
        SELECT pkjson,
               'EngineAddHoursMinutes' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'EngineAddHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'EngineAddMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineAddHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineAddMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'EngineAddHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'EngineAddMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineAddHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineAddMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('EngineAddHours', 'EngineAddMinutes')
        GROUP BY pkjson, action
    ),
    enginecurrenthoursminutes_changes AS (
        SELECT pkjson,
               'EngineCurrentHoursMinutes' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'EngineCurrentHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'EngineCurrentMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineCurrentHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineCurrentMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'EngineCurrentHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'EngineCurrentMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineCurrentHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineCurrentMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('EngineCurrentHours', 'EngineCurrentMinutes')
        GROUP BY pkjson, action
    ),
    engineupdatedhoursminutes_changes AS (
        SELECT pkjson,
               'EngineUpdatedHoursMinutes' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'EngineUpdatedHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'EngineUpdatedMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineUpdatedHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineUpdatedMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'EngineUpdatedHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'EngineUpdatedMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineUpdatedHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'EngineUpdatedMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('EngineUpdatedHours', 'EngineUpdatedMinutes')
        GROUP BY pkjson, action
    ),
    other_changes AS (
        SELECT pkjson,
                columnname,
                oldvalue,
                newvalue,
                action
        FROM   merged
        WHERE  columnname NOT IN ('EngineAddHours', 'EngineAddMinutes', 'EngineCurrentHours', 'EngineCurrentMinutes', 'EngineUpdatedHours', 'EngineUpdatedMinutes', 'AircraftEngineStartsMappingsId')
    ),
    all_changes AS (
        SELECT * FROM engineaddhoursminutes_changes
        UNION ALL
        SELECT * FROM enginecurrenthoursminutes_changes
        UNION ALL
        SELECT * FROM engineupdatedhoursminutes_changes
        UNION ALL
        SELECT * FROM other_changes
    )
    INSERT INTO dbo.AuditLog
            (
                SchemaName,
                TableName,
                PKJson,
                ColumnName,
                Action,
                OldValue,
                NewValue
            )
    SELECT N'dbo' AS SchemaName,
            N'AircraftEngineStartsMappings' AS TableName,
            a.pkjson,
            a.columnname,
            a.action,
            CASE
                WHEN a.ColumnName = 'EngineName' THEN 
                    CASE 
                        WHEN a.OldValue = 'ENGINE1' THEN 'ENGINE 1' 
                        WHEN a.OldValue = 'ENGINE2' THEN 'ENGINE 2' 
                        WHEN a.OldValue = 'ENGINE3' THEN 'ENGINE 3'
                        WHEN a.OldValue = 'ENGINE4' THEN 'ENGINE 4' 
                        ELSE a.OldValue
                    END            
                ELSE a.OldValue
            END AS OldValue,        
            CASE 
                WHEN a.ColumnName = 'EngineName' THEN 
                    CASE 
                        WHEN a.NewValue = 'ENGINE1' THEN 'ENGINE 1' 
                        WHEN a.NewValue = 'ENGINE2' THEN 'ENGINE 2' 
                        WHEN a.NewValue = 'ENGINE3' THEN 'ENGINE 3'
                        WHEN a.NewValue = 'ENGINE4' THEN 'ENGINE 4' 
                        ELSE a.NewValue
                    END            
                ELSE a.NewValue
            END AS NewValue
    FROM   all_changes a
    WHERE  a.columnname <> 'AircraftEngineStartsMappingsId'
            AND (
                    (
                        a.action = 'U'
                        AND (
                                (a.oldvalue IS NULL AND a.newvalue IS NOT NULL)
                                OR (a.oldvalue IS NOT NULL AND a.newvalue IS NULL)
                                OR (a.oldvalue <> a.newvalue)
                                OR (a.columnname = 'EngineName')
                            )
                    )
                    OR (a.action = 'I' AND a.newvalue IS NOT NULL)
                    OR (a.action = 'D' AND a.oldvalue IS NOT NULL)
                );
END;