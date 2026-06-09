CREATE TABLE [dbo].[AircraftMaintenanceProgram] (
    [ProgramId]                   BIGINT        IDENTITY (1, 1) NOT NULL,
    [AircraftRegistryId]          BIGINT        NOT NULL,
    [VersionNumber]               VARCHAR (50)  NULL,
    [TailNumber]                  VARCHAR (50)  NOT NULL,
    [AircraftMake]                VARCHAR (100) NULL,
    [AircraftModel]               VARCHAR (100) NULL,
    [SerialNumber]                VARCHAR (100) NULL,
    [MaintenanceType]             VARCHAR (200) NULL,
    [NextScheduledMaintenance]    DATETIME2 (7) NULL,
    [TemplateId]                  BIGINT        NULL,
    [TemplateVersionNumber]       VARCHAR (50)  NULL,
    [FlightHoursLimitHours]       INT           NULL,
    [FlightHoursLimitMinutes]     INT           NULL,
    [CyclesLimit]                 BIGINT        NULL,
    [TimeLimit]                   BIGINT        NULL,
    [LandingsLimit]               BIGINT        NULL,
    [EngineStartsLimit]           BIGINT        NULL,
    [FlightHoursRecordedHours]    INT           NULL,
    [FlightHoursRecordedMinutes]  INT           NULL,
    [CyclesRecorded]              BIGINT        NULL,
    [TimeRecorded]                BIGINT        NULL,
    [LandingsRecorded]            BIGINT        NULL,
    [EngineStartsRecorded]        BIGINT        NULL,
    [FlightHoursRemainingHours]   INT           NULL,
    [FlightHoursRemainingMinutes] INT           NULL,
    [CyclesRemaining]             BIGINT        NULL,
    [TimeRemaining]               BIGINT        NULL,
    [LandingsRemaining]           BIGINT        NULL,
    [EngineStartsRemaining]       BIGINT        NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_AMP_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_AMP_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_AMP_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_AMP_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MaintenanceTypeId]           BIGINT        NULL,
    [MaintenanceClassId]          BIGINT        NULL,
    [MtcCategoryId]               BIGINT        NULL,
    [IsMtceRecordUpdated]         BIT           DEFAULT ((0)) NULL,
    [WorksheetNumber]             VARCHAR (50)  NULL,
    [WorkOrderNum]                VARCHAR (30)  NULL,
    CONSTRAINT [PK_AircraftMaintenanceProgram] PRIMARY KEY CLUSTERED ([ProgramId] ASC),
    CONSTRAINT [CK_AMP_Minutes] CHECK (([FlightHoursLimitMinutes] IS NULL OR [FlightHoursLimitMinutes]>=(0) AND [FlightHoursLimitMinutes]<=(59)) AND ([FlightHoursRecordedMinutes] IS NULL OR [FlightHoursRecordedMinutes]>=(0) AND [FlightHoursRecordedMinutes]<=(59)) AND ([FlightHoursRemainingMinutes] IS NULL OR [FlightHoursRemainingMinutes]>=(0) AND [FlightHoursRemainingMinutes]<=(59))),
    CONSTRAINT [FK_AircraftMaintenanceProgram_AircraftRegistry] FOREIGN KEY ([AircraftRegistryId]) REFERENCES [dbo].[AircraftRegistryHeader] ([AircraftRegistryId]),
    CONSTRAINT [FK_AMP_MaintenanceClass] FOREIGN KEY ([MaintenanceClassId]) REFERENCES [dbo].[MaintenanceClass] ([MaintenanceClassId]),
    CONSTRAINT [FK_AMP_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AMP_Workflow] FOREIGN KEY ([TemplateId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);




GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_AircraftMaintenanceProgram]
ON [dbo].[AircraftMaintenanceProgram]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (
        SELECT d.[ProgramId],d.[AircraftRegistryId],d.[VersionNumber],d.[TailNumber],d.[AircraftMake],d.[AircraftModel],d.[SerialNumber],d.[MaintenanceType],d.[NextScheduledMaintenance],d.[TemplateId],d.[TemplateVersionNumber],d.[FlightHoursLimitHours],d.[FlightHoursLimitMinutes],d.[CyclesLimit],d.[TimeLimit],d.[LandingsLimit],d.[EngineStartsLimit],d.[FlightHoursRecordedHours],d.[FlightHoursRecordedMinutes],d.[CyclesRecorded],d.[TimeRecorded],d.[LandingsRecorded],d.[EngineStartsRecorded],d.[FlightHoursRemainingHours],d.[FlightHoursRemainingMinutes],d.[CyclesRemaining],d.[TimeRemaining],d.[LandingsRemaining],d.[EngineStartsRemaining],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[MaintenanceTypeId],d.[MaintenanceClassId],d.[MtcCategoryId],d.[IsMtceRecordUpdated],d.[WorksheetNumber],d.[WorkOrderNum]
        FROM deleted d),
    i AS (
        SELECT i.[ProgramId],i.[AircraftRegistryId],i.[VersionNumber],i.[TailNumber],i.[AircraftMake],i.[AircraftModel],i.[SerialNumber],i.[MaintenanceType],i.[NextScheduledMaintenance],i.[TemplateId],i.[TemplateVersionNumber],i.[FlightHoursLimitHours],i.[FlightHoursLimitMinutes],i.[CyclesLimit],i.[TimeLimit],i.[LandingsLimit],i.[EngineStartsLimit],i.[FlightHoursRecordedHours],i.[FlightHoursRecordedMinutes],i.[CyclesRecorded],i.[TimeRecorded],i.[LandingsRecorded],i.[EngineStartsRecorded],i.[FlightHoursRemainingHours],i.[FlightHoursRemainingMinutes],i.[CyclesRemaining],i.[TimeRemaining],i.[LandingsRemaining],i.[EngineStartsRemaining],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[MaintenanceTypeId],i.[MaintenanceClassId],i.[MtcCategoryId],i.[IsMtceRecordUpdated],i.[WorksheetNumber],i.[WorkOrderNum]
        FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.ProgramId, d.ProgramId ) AS ProgramId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.ProgramId IS NOT NULL AND d.ProgramId IS NOT NULL THEN 'U'
                WHEN i.ProgramId IS NOT NULL AND d.ProgramId IS NULL     THEN 'I'
                WHEN i.ProgramId IS NULL     AND d.ProgramId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.ProgramId, d.ProgramId) AS ProgramId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.ProgramId = d.ProgramId
    ),
    oldv AS (
        SELECT
            p.PKJson,
            p.ProgramId,
            v.[key] COLLATE DATABASE_DEFAULT AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'AircraftMaintenanceProgram'
                AND ign.ColumnName = v.[key] COLLATE DATABASE_DEFAULT
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.ProgramId ,
            v.[key] COLLATE DATABASE_DEFAULT AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'AircraftMaintenanceProgram'
                AND ign.ColumnName = v.[key] COLLATE DATABASE_DEFAULT
        )),
    merged AS (
        SELECT
            COALESCE(n.PKJson, o.PKJson)                AS PKJson,
            p.ProgramId,
            COALESCE(n.ColumnName, o.ColumnName)        AS ColumnName,
            o.OldValue,
            n.NewValue,
            p.Action
        FROM paired p
        LEFT JOIN oldv o
            ON o.ProgramId = p.ProgramId
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
        LEFT JOIN newv n
            ON n.ProgramId = p.ProgramId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.ProgramId = p.ProgramId
                AND o2.ColumnName    = n.ColumnName
        )
    ),    
    changed AS (
        SELECT *
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
                (m.Action = 'D' AND m.OldValue IS NOT NULL)
          
    ),    
    limithourminutes_changes AS (
        SELECT pkjson,
               'FlightHoursLimit' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHoursLimitHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightHoursLimitMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursLimitHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursLimitMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHoursLimitHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightHoursLimitMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursLimitHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursLimitMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM changed
        WHERE columnname IN ('FlightHoursLimitHours', 'FlightHoursLimitMinutes')
        GROUP BY pkjson, action
    ),
    recordedhourminutes_changes AS (
        SELECT pkjson,
               'FlightHoursRecorded' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHoursRecordedHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightHoursRecordedMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRecordedHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRecordedMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHoursRecordedHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightHoursRecordedMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRecordedHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRecordedMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM changed
        WHERE columnname IN ('FlightHoursRecordedHours', 'FlightHoursRecordedMinutes')
        GROUP BY pkjson, action
    ),
    remaininghourminutes_changes AS (
        SELECT pkjson,
               'FlightHoursRemaining' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHoursRemainingHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightHoursRemainingMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRemainingHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRemainingMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHoursRemainingHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightHoursRemainingMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRemainingHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHoursRemainingMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM changed
        WHERE columnname IN ('FlightHoursRemainingHours', 'FlightHoursRemainingMinutes')
        GROUP BY pkjson, action
    ),
    other_changes AS (
        SELECT
            pkjson,
            columnname,
            oldvalue,
            newvalue,
            action
        FROM changed
        WHERE columnname NOT IN (
            'FlightHoursLimitHours',
            'FlightHoursLimitMinutes',
            'FlightHoursRecordedHours',
            'FlightHoursRecordedMinutes',
            'FlightHoursRemainingHours',
            'FlightHoursRemainingMinutes'
        )
    ),
    all_changes AS (
        SELECT * FROM limithourminutes_changes
        UNION ALL
        SELECT * FROM recordedhourminutes_changes
        UNION ALL
        SELECT * FROM remaininghourminutes_changes
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
    LEFT JOIN [dbo].[Workflow] wfOld WITH(NOLOCK) ON m.ColumnName = 'TemplateId' AND TRY_CAST(m.OldValue AS BIGINT) = wfOld.WorkflowId
    LEFT JOIN [dbo].[Workflow] wfNew WITH(NOLOCK) ON m.ColumnName = 'TemplateId' AND TRY_CAST(m.NewValue AS BIGINT) = wfNew.WorkflowId
    LEFT JOIN [dbo].[MaintenanceCategory] mcOld WITH(NOLOCK) ON m.ColumnName = 'MtcCategoryId' AND TRY_CAST(m.OldValue AS BIGINT) = mcOld.MtcCategoryId
    LEFT JOIN [dbo].[MaintenanceCategory] mcNew WITH(NOLOCK) ON m.ColumnName = 'MtcCategoryId' AND TRY_CAST(m.NewValue AS BIGINT) = mcNew.MtcCategoryId
END;
GO
