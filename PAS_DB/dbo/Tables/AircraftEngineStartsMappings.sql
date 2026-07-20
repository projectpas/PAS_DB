CREATE TABLE [dbo].[AircraftEngineStartsMappings] (
    [AircraftEngineStartsMappingsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AircraftCycleTimeMappingsId]    BIGINT          NULL,
    [EngineRegistryId]               BIGINT          NOT NULL,
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
    [CreatedDate]                    DATETIME2 (7)   CONSTRAINT [DF__tmp_ms_xx__Creat__07534DF3] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   NOT NULL,
    [IsActive]                       BIT             CONSTRAINT [DF__tmp_ms_xx__IsAct__0847722C] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT             CONSTRAINT [DF__tmp_ms_xx__IsDel__093B9665] DEFAULT ((0)) NOT NULL,
    [Minutes]                        DECIMAL (18, 6) NULL,
    [CurruntMinutes]                 DECIMAL (18, 6) NULL,
    [CumulativeMinutes]              DECIMAL (18, 6) NULL,
    CONSTRAINT [PK__tmp_ms_x__23E8FB0BAD197607] PRIMARY KEY CLUSTERED ([AircraftEngineStartsMappingsId] ASC),
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
        WHERE  columnname IN ('EngineAddStarts', 'EngineCurrentStarts', 'EngineUpdatedStarts')
    ),
    all_changes AS (
        SELECT * FROM engineaddhoursminutes_changes
        UNION ALL
        SELECT * FROM enginecurrenthoursminutes_changes
        UNION ALL
        SELECT * FROM engineupdatedhoursminutes_changes
        UNION ALL
        SELECT * FROM other_changes
    ),
    changed_engine_rows AS (
        SELECT pkjson,
               action
        FROM merged
        GROUP BY pkjson, action
        HAVING
            (
                action = 'U'
                AND
                (
                    MAX(CASE
                            WHEN columnname IN ('EngineAddHours', 'EngineAddMinutes', 'EngineAddStarts')
                                AND ISNULL(TRY_CONVERT(DECIMAL(18,6), newvalue), 0) <> 0
                            THEN 1 ELSE 0
                        END) = 1
                    OR
                    MAX(CASE
                            WHEN columnname IN ('EngineCurrentHours', 'EngineCurrentMinutes', 'EngineCurrentStarts', 'EngineUpdatedHours', 'EngineUpdatedMinutes', 'EngineUpdatedStarts')
                                AND
                                (
                                    (oldvalue IS NULL AND newvalue IS NOT NULL)
                                    OR (oldvalue IS NOT NULL AND newvalue IS NULL)
                                    OR (oldvalue <> newvalue)
                                )
                            THEN 1 ELSE 0
                        END) = 1
                )
            )
            OR
            (
                action = 'I'
                AND MAX(CASE
                            WHEN columnname IN ('EngineAddHours', 'EngineAddMinutes', 'EngineAddStarts', 'EngineCurrentHours', 'EngineCurrentMinutes', 'EngineCurrentStarts', 'EngineUpdatedHours', 'EngineUpdatedMinutes', 'EngineUpdatedStarts')
                                AND ISNULL(TRY_CONVERT(DECIMAL(18,6), newvalue), 0) <> 0
                            THEN 1 ELSE 0
                        END) = 1
            )
            OR
            (
                action = 'D'
                AND MAX(CASE
                            WHEN columnname IN ('EngineAddHours', 'EngineAddMinutes', 'EngineAddStarts', 'EngineCurrentHours', 'EngineCurrentMinutes', 'EngineCurrentStarts', 'EngineUpdatedHours', 'EngineUpdatedMinutes', 'EngineUpdatedStarts')
                                AND ISNULL(TRY_CONVERT(DECIMAL(18,6), oldvalue), 0) <> 0
                            THEN 1 ELSE 0
                        END) = 1
            )
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
            a.OldValue,
            a.NewValue            
    FROM all_changes a
   INNER JOIN changed_engine_rows cer
        ON cer.pkjson = a.pkjson
        AND cer.action = a.action
    WHERE  a.columnname IN
            (
                'EngineAddHoursMinutes',
                'EngineAddStarts',
                'EngineCurrentHoursMinutes',
                'EngineCurrentStarts',
                'EngineUpdatedHoursMinutes',
                'EngineUpdatedStarts'
            )
            AND (
                    (a.action = 'U' AND a.newvalue IS NOT NULL)
                    OR (a.action = 'I' AND a.newvalue IS NOT NULL)
                    OR (a.action = 'D' AND a.oldvalue IS NOT NULL)
                );
END;