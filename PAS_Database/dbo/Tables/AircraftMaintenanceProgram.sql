CREATE TABLE [dbo].[AircraftMaintenanceProgram] (
    [ProgramId]                    BIGINT        IDENTITY (1, 1) NOT NULL,
    [AircraftRegistryId]           BIGINT        NOT NULL,
    [VersionNumber]                VARCHAR (50)  NULL,
    [TailNumber]                   VARCHAR (50)  NOT NULL,
    [AircraftMake]                 VARCHAR (100) NULL,
    [AircraftModel]                VARCHAR (100) NULL,
    [SerialNumber]                 VARCHAR (100) NULL,
    [MaintenanceType]              VARCHAR (MAX) NULL,
    [NextScheduledMaintenance]     DATETIME2 (7) NULL,
    [TemplateId]                   BIGINT        NULL,
    [TemplateVersionNumber]        VARCHAR (50)  NULL,
    [FlightHoursLimitHours]        INT           NULL,
    [FlightHoursLimitMinutes]      INT           NULL,
    [CyclesLimit]                  BIGINT        NULL,
    [TimeLimit]                    BIGINT        NULL,
    [LandingsLimit]                BIGINT        NULL,
    [EngineStartsLimit]            BIGINT        NULL,
    [FlightHoursRecordedHours]     INT           NULL,
    [FlightHoursRecordedMinutes]   INT           NULL,
    [CyclesRecorded]               BIGINT        NULL,
    [TimeRecorded]                 BIGINT        NULL,
    [LandingsRecorded]             BIGINT        NULL,
    [EngineStartsRecorded]         BIGINT        NULL,
    [FlightHoursRemainingHours]    INT           NULL,
    [FlightHoursRemainingMinutes]  INT           NULL,
    [CyclesRemaining]              BIGINT        NULL,
    [TimeRemaining]                BIGINT        NULL,
    [LandingsRemaining]            BIGINT        NULL,
    [EngineStartsRemaining]        BIGINT        NULL,
    [IsScheduled]                  BIT           CONSTRAINT [DF_AircraftMaintenanceProgram_IsScheduled] DEFAULT ((0)) NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_AMP_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_AMP_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [DF_AMP_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           CONSTRAINT [DF_AMP_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MaintenanceTypeId]            BIGINT        NULL,
    [MaintenanceClassId]           BIGINT        NULL,
    [MtcCategoryId]                BIGINT        NULL,
    [AircraftPublicationId]        BIGINT        NULL,
    [IsMtceRecordUpdated]          BIT           CONSTRAINT [DF__AircraftM__IsMtc__1F89FEE0] DEFAULT ((0)) NULL,
    [WorksheetNumber]              VARCHAR (50)  NULL,
    [WorkOrderNum]                 VARCHAR (30)  NULL,
    [LastinspectedById]            BIGINT        NULL,
    [Description]                  VARCHAR (256) NULL,
    [LastInspectedDate]            DATETIME2 (7) NULL,
    [IsFromAircraft]               BIT           NULL,
    [EngineRegistryId]             BIGINT        NULL,
    [FlightHoursLimitMonthsOrDays] INT           NULL,
    [SequenceNo]                   BIGINT        NULL,
    CONSTRAINT [PK_AircraftMaintenanceProgram] PRIMARY KEY CLUSTERED ([ProgramId] ASC),
    CONSTRAINT [CK_AMP_Minutes] CHECK (([FlightHoursLimitMinutes] IS NULL OR [FlightHoursLimitMinutes]>=(0) AND [FlightHoursLimitMinutes]<=(59)) AND ([FlightHoursRecordedMinutes] IS NULL OR [FlightHoursRecordedMinutes]>=(0) AND [FlightHoursRecordedMinutes]<=(59)) AND ([FlightHoursRemainingMinutes] IS NULL OR [FlightHoursRemainingMinutes]>=(0) AND [FlightHoursRemainingMinutes]<=(59))),
    CONSTRAINT [FK_AMP_MaintenanceClass] FOREIGN KEY ([MaintenanceClassId]) REFERENCES [dbo].[MaintenanceClass] ([MaintenanceClassId]),
    CONSTRAINT [FK_AMP_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AMP_Workflow] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_AircraftMaintenanceProgram]
ON [dbo].[AircraftMaintenanceProgram]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    ;WITH
    d AS (
        SELECT d.[ProgramId], d.[AircraftRegistryId], d.[VersionNumber], d.[TailNumber], d.[AircraftMake], d.[AircraftModel], d.[SerialNumber], d.[MaintenanceType], d.[NextScheduledMaintenance], d.[TemplateId], d.[TemplateVersionNumber], d.[FlightHoursLimitHours], d.[FlightHoursLimitMinutes], d.[CyclesLimit], d.[TimeLimit], d.[LandingsLimit], d.[EngineStartsLimit], d.[FlightHoursRecordedHours], d.[FlightHoursRecordedMinutes], d.[CyclesRecorded], d.[TimeRecorded], d.[LandingsRecorded], d.[EngineStartsRecorded], d.[FlightHoursRemainingHours], d.[FlightHoursRemainingMinutes], d.[CyclesRemaining], d.[TimeRemaining], d.[LandingsRemaining], d.[EngineStartsRemaining], d.[IsScheduled], d.[MasterCompanyId], d.[CreatedBy], d.[UpdatedBy], d.[CreatedDate], d.[UpdatedDate], d.[IsActive], d.[IsDeleted], d.[MaintenanceTypeId], d.[MaintenanceClassId], d.[MtcCategoryId], d.[AircraftPublicationId], d.[IsMtceRecordUpdated], d.[WorksheetNumber], d.[WorkOrderNum], d.[LastinspectedById], d.[Description], d.[LastInspectedDate], d.[IsFromAircraft], d.[EngineRegistryId], d.[FlightHoursLimitMonthsOrDays], d.[SequenceNo]
        FROM deleted d
    ),
    i AS (
        SELECT i.[ProgramId], i.[AircraftRegistryId], i.[VersionNumber], i.[TailNumber], i.[AircraftMake], i.[AircraftModel], i.[SerialNumber], i.[MaintenanceType], i.[NextScheduledMaintenance], i.[TemplateId], i.[TemplateVersionNumber], i.[FlightHoursLimitHours], i.[FlightHoursLimitMinutes], i.[CyclesLimit], i.[TimeLimit], i.[LandingsLimit], i.[EngineStartsLimit], i.[FlightHoursRecordedHours], i.[FlightHoursRecordedMinutes], i.[CyclesRecorded], i.[TimeRecorded], i.[LandingsRecorded], i.[EngineStartsRecorded], i.[FlightHoursRemainingHours], i.[FlightHoursRemainingMinutes], i.[CyclesRemaining], i.[TimeRemaining], i.[LandingsRemaining], i.[EngineStartsRemaining], i.[IsScheduled], i.[MasterCompanyId], i.[CreatedBy], i.[UpdatedBy], i.[CreatedDate], i.[UpdatedDate], i.[IsActive], i.[IsDeleted], i.[MaintenanceTypeId], i.[MaintenanceClassId], i.[MtcCategoryId], i.[AircraftPublicationId], i.[IsMtceRecordUpdated], i.[WorksheetNumber], i.[WorkOrderNum], i.[LastinspectedById], i.[Description], i.[LastInspectedDate], i.[IsFromAircraft], i.[EngineRegistryId], i.[FlightHoursLimitMonthsOrDays], i.[SequenceNo]
        FROM inserted i
    ),
    paired AS (
        SELECT
            COALESCE(i.ProgramId, d.ProgramId) AS ProgramId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json,
            CASE
                WHEN i.ProgramId IS NOT NULL AND d.ProgramId IS NOT NULL THEN 'U'
                WHEN i.ProgramId IS NOT NULL AND d.ProgramId IS NULL THEN 'I'
                WHEN i.ProgramId IS NULL AND d.ProgramId IS NOT NULL THEN 'D'
            END AS Action,
            (SELECT COALESCE(i.ProgramId, d.ProgramId) AS ProgramId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i ON i.ProgramId = d.ProgramId
    ),
    oldv AS (
        SELECT
            p.PKJson,
            p.ProgramId,
            v.[key] COLLATE DATABASE_DEFAULT AS ColumnName,
            v.value AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH (NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName = N'AircraftMaintenanceProgram'
                AND ign.ColumnName = v.[key] COLLATE DATABASE_DEFAULT
        )
    ),
    newv AS (
        SELECT
            p.PKJson,
            p.ProgramId,
            v.[key] COLLATE DATABASE_DEFAULT AS ColumnName,
            v.value AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH (NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName = N'AircraftMaintenanceProgram'
                AND ign.ColumnName = v.[key] COLLATE DATABASE_DEFAULT
        )
    ),
    merged AS (
        SELECT
            COALESCE(n.PKJson, o.PKJson) AS PKJson,
            p.ProgramId,
            COALESCE(n.ColumnName, o.ColumnName) AS ColumnName,
            o.OldValue,
            n.NewValue,
            p.Action
        FROM paired p
        LEFT JOIN oldv o ON o.ProgramId = p.ProgramId
        LEFT JOIN newv n
            ON n.ProgramId = p.ProgramId
            AND n.ColumnName = o.ColumnName

        UNION ALL

        SELECT
            n.PKJson,
            p.ProgramId,
            n.ColumnName,
            NULL AS OldValue,
            n.NewValue,
            p.Action
        FROM paired p
        LEFT JOIN newv n ON n.ProgramId = p.ProgramId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.ProgramId = p.ProgramId
                AND o2.ColumnName = n.ColumnName
        )
    ),
    changed AS (
        SELECT *
        FROM merged m
        WHERE (m.Action = 'U' AND (
                   (m.OldValue IS NULL AND m.NewValue IS NOT NULL)
                OR (m.OldValue IS NOT NULL AND m.NewValue IS NULL)
                OR (m.OldValue <> m.NewValue)
            ))
            OR (m.Action = 'I' AND m.NewValue IS NOT NULL)
            OR (m.Action = 'D' AND m.OldValue IS NOT NULL)
    ),
    hourminute_changes AS (
        SELECT
            p.PKJson AS pkjson,
            hm.ColumnName AS columnname,
            CASE
                WHEN hm.OldHours IS NULL AND hm.OldMinutes IS NULL THEN NULL
                ELSE CONCAT(CAST(COALESCE(TRY_CAST(hm.OldHours AS INT), 0) AS VARCHAR(10)), ':',
                            RIGHT('00' + CAST(COALESCE(TRY_CAST(hm.OldMinutes AS INT), 0) AS VARCHAR(10)), 2))
            END AS oldvalue,
            CASE
                WHEN hm.NewHours IS NULL AND hm.NewMinutes IS NULL THEN NULL
                ELSE CONCAT(CAST(COALESCE(TRY_CAST(hm.NewHours AS INT), 0) AS VARCHAR(10)), ':',
                            RIGHT('00' + CAST(COALESCE(TRY_CAST(hm.NewMinutes AS INT), 0) AS VARCHAR(10)), 2))
            END AS newvalue,
            p.Action AS action
        FROM paired p
        CROSS APPLY (VALUES
            (N'FlightHoursLimit',
             JSON_VALUE(p.old_row_json, '$.FlightHoursLimitHours'),
             JSON_VALUE(p.old_row_json, '$.FlightHoursLimitMinutes'),
             JSON_VALUE(p.new_row_json, '$.FlightHoursLimitHours'),
             JSON_VALUE(p.new_row_json, '$.FlightHoursLimitMinutes'),
             N'FlightHoursLimitHours',
             N'FlightHoursLimitMinutes'),
            (N'FlightHoursRecorded',
             JSON_VALUE(p.old_row_json, '$.FlightHoursRecordedHours'),
             JSON_VALUE(p.old_row_json, '$.FlightHoursRecordedMinutes'),
             JSON_VALUE(p.new_row_json, '$.FlightHoursRecordedHours'),
             JSON_VALUE(p.new_row_json, '$.FlightHoursRecordedMinutes'),
             N'FlightHoursRecordedHours',
             N'FlightHoursRecordedMinutes'),
            (N'FlightHoursRemaining',
             JSON_VALUE(p.old_row_json, '$.FlightHoursRemainingHours'),
             JSON_VALUE(p.old_row_json, '$.FlightHoursRemainingMinutes'),
             JSON_VALUE(p.new_row_json, '$.FlightHoursRemainingHours'),
             JSON_VALUE(p.new_row_json, '$.FlightHoursRemainingMinutes'),
             N'FlightHoursRemainingHours',
             N'FlightHoursRemainingMinutes')
        ) hm(ColumnName, OldHours, OldMinutes, NewHours, NewMinutes, HoursColumnName, MinutesColumnName)
        WHERE EXISTS (
            SELECT 1
            FROM changed c
            WHERE c.ProgramId = p.ProgramId
              AND c.ColumnName IN (hm.HoursColumnName, hm.MinutesColumnName)
        )
    ),
    other_changes AS (
        SELECT
            PKJson,
            ColumnName,
            OldValue,
            NewValue,
            Action
        FROM changed
        WHERE ColumnName NOT IN (
            'FlightHoursLimitHours',
            'FlightHoursLimitMinutes',
            'FlightHoursRecordedHours',
            'FlightHoursRecordedMinutes',
            'FlightHoursRemainingHours',
            'FlightHoursRemainingMinutes'
        )
    ),
    all_changes AS (
        SELECT * FROM hourminute_changes
        UNION ALL
        SELECT * FROM other_changes
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'AircraftMaintenanceProgram' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        CASE
            WHEN m.ColumnName = 'TemplateId' THEN wfOld.WorkOrderNumber
            WHEN m.ColumnName = 'MtcCategoryId' THEN mcOld.MtcCategory
            ELSE m.OldValue
        END AS OldValue,
        CASE
            WHEN m.ColumnName = 'TemplateId' THEN wfNew.WorkOrderNumber
            WHEN m.ColumnName = 'MtcCategoryId' THEN mcNew.MtcCategory
            ELSE m.NewValue
        END AS NewValue
    FROM all_changes m
    LEFT JOIN [dbo].[Workflow] wfOld WITH (NOLOCK)
        ON m.ColumnName = 'TemplateId'
        AND TRY_CAST(m.OldValue AS BIGINT) = wfOld.WorkflowId
    LEFT JOIN [dbo].[Workflow] wfNew WITH (NOLOCK)
        ON m.ColumnName = 'TemplateId'
        AND TRY_CAST(m.NewValue AS BIGINT) = wfNew.WorkflowId
    LEFT JOIN [dbo].[MaintenanceCategory] mcOld WITH (NOLOCK)
        ON m.ColumnName = 'MtcCategoryId'
        AND TRY_CAST(m.OldValue AS BIGINT) = mcOld.MtcCategoryId
    LEFT JOIN [dbo].[MaintenanceCategory] mcNew WITH (NOLOCK)
        ON m.ColumnName = 'MtcCategoryId'
        AND TRY_CAST(m.NewValue AS BIGINT) = mcNew.MtcCategoryId;
END;