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
CREATE   TRIGGER [dbo].[trg_Audit_dbo_AircraftCycleTimeMappings] ON [dbo].[AircraftCycleTimeMappings] after
INSERT,
UPDATE,
DELETE AS BEGIN SET nocount ON; ;WITH d AS
(
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
       FROM   deleted d), i AS
(
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
       FROM   inserted i), paired AS
(
                SELECT          COALESCE(i.aircraftcycletimemappingsid, d.aircraftcycletimemappingsid ) AS aircraftcycletimemappingsid,
                                (
                                       SELECT d.* FOR json              path,
                                              without_array_wrapper) AS old_row_json,
                                (
                                       SELECT i.* FOR json              path,
                                              without_array_wrapper) AS new_row_json,
                                CASE
                                                WHEN i.aircraftcycletimemappingsid IS NOT NULL
                                                AND             d.aircraftcycletimemappingsid IS NOT NULL THEN 'U'
                                                WHEN i.aircraftcycletimemappingsid IS NOT NULL
                                                AND             d.aircraftcycletimemappingsid IS NULL THEN 'I'
                                                WHEN i.aircraftcycletimemappingsid IS NULL
                                                AND             d.aircraftcycletimemappingsid IS NOT NULL THEN 'D'
                                END AS action,
                                (
                                       SELECT COALESCE(i.aircraftcycletimemappingsid, d.aircraftcycletimemappingsid) AS aircraftcycletimemappingsid FOR json path,
                                              without_array_wrapper) AS                                                 pkjson
                FROM            d
                FULL OUTER JOIN i
                ON              i.aircraftcycletimemappingsid = d.aircraftcycletimemappingsid ), oldv AS
(
            SELECT      p.pkjson,
                        p.aircraftcycletimemappingsid,
                        v.[key] AS columnname,
                        v.value AS oldvalue
            FROM        paired p
            CROSS apply openjson(p.old_row_json) v
            WHERE       NOT EXISTS
                        (
                               SELECT 1
                               FROM   dbo.ignorecolumn ign WITH(nolock)
                               WHERE  ign.schemaname = N'dbo'
                               AND    ign.tablename = N'AircraftCycleTimeMappings'
                               AND    ign.columnname = N'AircraftCycleTimeMappingsId' )), newv AS
(
            SELECT      p.pkjson,
                        p.aircraftcycletimemappingsid ,
                        v.[key] AS columnname,
                        v.value AS newvalue
            FROM        paired p
            CROSS apply openjson(p.new_row_json) v
            WHERE       NOT EXISTS
                        (
                               SELECT 1
                               FROM   dbo.ignorecolumn ign WITH(nolock)
                               WHERE  ign.schemaname = N'dbo'
                               AND    ign.tablename = N'AircraftCycleTimeMappings'
                               AND    ign.columnname = N'AircraftCycleTimeMappingsId' )), merged AS
(
          SELECT    COALESCE(n.pkjson, o.pkjson)         AS pkjson,
                    COALESCE(n.columnname, o.columnname) AS columnname,
                    o.oldvalue,
                    n.newvalue,
                    p.action
          FROM      paired p
          LEFT JOIN oldv o
          ON        o.aircraftcycletimemappingsid = p.aircraftcycletimemappingsid
          LEFT JOIN newv n
          ON        n.aircraftcycletimemappingsid = p.aircraftcycletimemappingsid
          AND       n.columnname = o.columnname
          UNION ALL
          SELECT    n.pkjson,
                    n.columnname,
                    NULL AS oldvalue,
                    n.newvalue,
                    p.action
          FROM      paired p
          LEFT JOIN newv n
          ON        n.aircraftcycletimemappingsid = p.aircraftcycletimemappingsid
          WHERE     NOT EXISTS
                    (
                           SELECT 1
                           FROM   oldv o2
                           WHERE  o2.aircraftcycletimemappingsid = p.aircraftcycletimemappingsid
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
SELECT N'dbo'                       AS schemaname,
       N'AircraftCycleTimeMappings' AS tablename,
       m.pkjson,
       m.columnname,
       m.action,
       m.oldvalue,
       m.newvalue
FROM   merged m
WHERE  m.columnname <> 'AircraftCycleTimeMappingsId'
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