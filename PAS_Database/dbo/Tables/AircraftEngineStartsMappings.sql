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
CREATE   TRIGGER [dbo].[trg_Audit_dbo_AircraftEngineStartsMappings] ON [dbo].[AircraftEngineStartsMappings] after
INSERT,
UPDATE,
DELETE AS BEGIN SET nocount ON; ;WITH d AS
(
       SELECT d.[AircraftEngineStartsMappingsId],
              d.[AircraftCycleTimeMappingsId],
              d.[EngineName],
              d.[Hours] AS EngineHours,
              d.[CurruntHours] AS EngineCurruntHours,
              d.[CumulativeHours] AS EngineCumulativeHours,
              d.[Starts] AS EngineStarts,
              d.[CurruntStarts] AS EngineCurruntStarts,
              d.[CumulativeStarts] AS EngineCumulativeStarts,
              d.[Memo] AS EngineMemo,
              d.[MasterCompanyId] AS EngineMasterCompanyId,
              d.[CreatedBy] AS EngineCreatedBy,
              d.[UpdatedBy] AS EngineUpdatedBy,
              d.[CreatedDate] AS EngineCreatedDate,
              d.[UpdatedDate] AS EngineUpdatedDate,
              d.[IsActive] AS EngineIsActive,
              d.[IsDeleted] AS EngineIsDeleted,
              d.[Minutes] AS EngineMinutes,
              d.[CurruntMinutes] AS EngineCurruntMinutes,
              d.[CumulativeMinutes] AS EngineCumulativeMinutes
       FROM   deleted d), i AS
(
       SELECT i.[AircraftEngineStartsMappingsId],
              i.[AircraftCycleTimeMappingsId],
              i.[EngineName],
              i.[Hours] AS EngineHours,
              i.[CurruntHours] AS EngineCurruntHours,
              i.[CumulativeHours] AS EngineCumulativeHours,
              i.[Starts] AS EngineStarts,
              i.[CurruntStarts] AS EngineCurruntStarts,
              i.[CumulativeStarts] AS EngineCumulativeStarts,
              i.[Memo] AS EngineMemo,
              i.[MasterCompanyId] AS EngineMasterCompanyId,
              i.[CreatedBy] AS EngineCreatedBy,
              i.[UpdatedBy] AS EngineUpdatedBy,
              i.[CreatedDate] AS EngineCreatedDate,
              i.[UpdatedDate] AS EngineUpdatedDate,
              i.[IsActive] AS EngineIsActive,
              i.[IsDeleted] AS EngineIsDeleted,
              i.[Minutes] AS EngineMinutes,
              i.[CurruntMinutes] AS EngineCurruntMinutes,
              i.[CumulativeMinutes] AS EngineCumulativeMinutes
       FROM   inserted i), paired AS
(
                SELECT          COALESCE(i.aircraftenginestartsmappingsid, d.aircraftenginestartsmappingsid ) AS aircraftenginestartsmappingsid,
                                (
                                       SELECT d.* FOR json              path,
                                              without_array_wrapper) AS old_row_json,
                                (
                                       SELECT i.* FOR json              path,
                                              without_array_wrapper) AS new_row_json,
                                CASE
                                                WHEN i.aircraftenginestartsmappingsid IS NOT NULL
                                                AND             d.aircraftenginestartsmappingsid IS NOT NULL THEN 'U'
                                                WHEN i.aircraftenginestartsmappingsid IS NOT NULL
                                                AND             d.aircraftenginestartsmappingsid IS NULL THEN 'I'
                                                WHEN i.aircraftenginestartsmappingsid IS NULL
                                                AND             d.aircraftenginestartsmappingsid IS NOT NULL THEN 'D'
                                END AS action,
                                (
                                       SELECT COALESCE(i.aircraftenginestartsmappingsid, d.aircraftenginestartsmappingsid) AS aircraftenginestartsmappingsid FOR json path,
                                              without_array_wrapper) AS                                                       pkjson
                FROM            d
                FULL OUTER JOIN i
                ON              i.aircraftenginestartsmappingsid = d.aircraftenginestartsmappingsid ), oldv AS
(
            SELECT      p.pkjson,
                        p.aircraftenginestartsmappingsid,
                        v.[key] AS columnname,
                        v.value AS oldvalue
            FROM        paired p
            CROSS apply openjson(p.old_row_json) v
            WHERE       NOT EXISTS
                        (
                               SELECT 1
                               FROM   dbo.ignorecolumn ign WITH(nolock)
                               WHERE  ign.schemaname = N'dbo'
                               AND    ign.tablename = N'AircraftEngineStartsMappings'
                               AND    ign.columnname = N'AircraftEngineStartsMappingsId' )), newv AS
(
            SELECT      p.pkjson,
                        p.aircraftenginestartsmappingsid ,
                        v.[key] AS columnname,
                        v.value AS newvalue
            FROM        paired p
            CROSS apply openjson(p.new_row_json) v
            WHERE       NOT EXISTS
                        (
                               SELECT 1
                               FROM   dbo.ignorecolumn ign WITH(nolock)
                               WHERE  ign.schemaname = N'dbo'
                               AND    ign.tablename = N'AircraftEngineStartsMappings'
                               AND    ign.columnname = N'AircraftEngineStartsMappingsId' )), merged AS
(
          SELECT    COALESCE(n.pkjson, o.pkjson)         AS pkjson,
                    COALESCE(n.columnname, o.columnname) AS columnname,
                    o.oldvalue,
                    n.newvalue,
                    p.action
          FROM      paired p
          LEFT JOIN oldv o
          ON        o.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
          LEFT JOIN newv n
          ON        n.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
          AND       n.columnname = o.columnname
          UNION ALL
          SELECT    n.pkjson,
                    n.columnname,
                    NULL AS oldvalue,
                    n.newvalue,
                    p.action
          FROM      paired p
          LEFT JOIN newv n
          ON        n.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
          WHERE     NOT EXISTS
                    (
                           SELECT 1
                           FROM   oldv o2
                           WHERE  o2.aircraftenginestartsmappingsid = p.aircraftenginestartsmappingsid
                           AND    o2.columnname = n.columnname ) )
INSERT dbo.auditlog
       (
              schemaname,
              tablename,
              pkjson,
              columnname,
              action,
              oldvalue,
              newvalue
       )
SELECT N'dbo'                          AS schemaname,
       N'AircraftEngineStartsMappings' AS tablename,
       m.pkjson,
       m.columnname,
       m.action,
       m.oldvalue,
       m.newvalue
FROM   merged m
WHERE  m.columnname <> 'AircraftEngineStartsMappingsId'
AND    ( (
                     m.action = 'U'
              AND    ( (
                                   m.oldvalue IS NULL
                            AND    m.newvalue IS NOT NULL)
                     OR     (
                                   m.oldvalue IS NOT NULL
                            AND    m.newvalue IS NULL)
                     OR     (
                                   m.oldvalue <> m.newvalue) ))
       OR     (
                     m.action = 'I'
              AND    m.newvalue IS NOT NULL)
       OR     (
                     m.action = 'D'
              AND    m.oldvalue IS NOT NULL));
END;