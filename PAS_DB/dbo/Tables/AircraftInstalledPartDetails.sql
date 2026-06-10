CREATE TABLE [dbo].[AircraftInstalledPartDetails] (
    [AircraftInstalledPartDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AircraftRegistryId]             BIGINT          NOT NULL,
    [ATAChapterId]                   BIGINT          NOT NULL,
    [ItemMasterId]                   BIGINT          NOT NULL,
    [PartNumber]                     VARCHAR (50)    NULL,
    [PartDescription]                NVARCHAR (MAX)  NULL,
    [IsLLP]                          BIT             DEFAULT ((0)) NOT NULL,
    [IsSerialized]                   BIT             DEFAULT ((0)) NOT NULL,
    [SerialNumber]                   VARCHAR (100)   NULL,
    [DateInstalled]                  DATETIME2 (7)   NULL,
    [PositionCode]                   VARCHAR (256)   NULL,
    [Hours]                          DECIMAL (18, 2) NULL,
    [Minutes]                        DECIMAL (18, 2) NULL,
    [FlightHours]                    DECIMAL (18, 2) NULL,
    [Cycles]                         DECIMAL (18, 2) NULL,
    [Landings]                       BIGINT          NULL,
    [EngineStarts]                   BIGINT          NULL,
    [Memo]                           NVARCHAR (MAX)  NULL,
    [MasterCompanyId]                INT             NOT NULL,
    [CreatedBy]                      VARCHAR (256)   NOT NULL,
    [UpdatedBy]                      VARCHAR (256)   NOT NULL,
    [CreatedDate]                    DATETIME2 (7)   DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)   NOT NULL,
    [IsActive]                       BIT             DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT             DEFAULT ((0)) NOT NULL,
    [StockLineId]                    BIGINT          NULL,
    [ConditionId]                    BIGINT          NULL,
    [Quantity]                       DECIMAL (18, 6) NULL,
    [PositionCodeId]                 BIGINT          NULL,
    [SequenceNum]                    INT             NULL,
    [partFlightHours]                DECIMAL (18, 6) NULL,
    [partCycles]                     DECIMAL (18, 6) NULL,
    [partLandings]                   DECIMAL (18, 6) NULL,
    [partEngineStarts]               DECIMAL (18, 6) NULL,
    [PartFlightMinutes]              DECIMAL (18, 6) NULL,
    [FlightMinutes]                  DECIMAL (18, 6) NULL,
    [InstallFlightHours]             DECIMAL (18, 6) NULL,
    [InstallFlightTime]              DECIMAL (18, 6) NULL,
    [InstallCycles]                  DECIMAL (18, 6) NULL,
    [LastFlownDate]                  DATETIME2 (7)   NULL,
    PRIMARY KEY CLUSTERED ([AircraftInstalledPartDetailsId] ASC),
    CONSTRAINT [FK_AircraftInstalledPartDetails_AircraftRegistryId] FOREIGN KEY ([AircraftRegistryId]) REFERENCES [dbo].[AircraftRegistryHeader] ([AircraftRegistryId]),
    CONSTRAINT [FK_AircraftInstalledPartDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

GO

CREATE TRIGGER [dbo].[trg_Audit_dbo_AircraftInstalledPartDetails]
ON [dbo].[AircraftInstalledPartDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[AircraftInstalledPartDetailsId],d.[AircraftRegistryId],d.[ATAChapterId],d.[ItemMasterId],d.[PartNumber],d.[PartDescription],d.[IsLLP],d.[IsSerialized],d.[SerialNumber],d.[DateInstalled],d.[PositionCode],d.[Hours],d.[Minutes],d.[FlightHours],d.[Cycles],d.[Landings],d.[EngineStarts],d.[Memo],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[StockLineId],d.[ConditionId],d.[Quantity],d.[PositionCodeId],d.[SequenceNum],d.[partFlightHours],d.[partCycles],d.[partLandings],d.[partEngineStarts],d.[PartFlightMinutes],d.[FlightMinutes],d.[InstallFlightHours],d.[InstallFlightTime],d.[InstallCycles],d.[LastFlownDate] FROM deleted d),
    i AS (SELECT i.[AircraftInstalledPartDetailsId],i.[AircraftRegistryId],i.[ATAChapterId],i.[ItemMasterId],i.[PartNumber],i.[PartDescription],i.[IsLLP],i.[IsSerialized],i.[SerialNumber],i.[DateInstalled],i.[PositionCode],i.[Hours],i.[Minutes],i.[FlightHours],i.[Cycles],i.[Landings],i.[EngineStarts],i.[Memo],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[StockLineId],i.[ConditionId],i.[Quantity],i.[PositionCodeId],i.[SequenceNum],i.[partFlightHours],i.[partCycles],i.[partLandings],i.[partEngineStarts],i.[PartFlightMinutes],i.[FlightMinutes],i.[InstallFlightHours],i.[InstallFlightTime],i.[InstallCycles],i.[LastFlownDate] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.AircraftInstalledPartDetailsId, d.AircraftInstalledPartDetailsId ) AS AircraftInstalledPartDetailsId,
            (SELECT d.*
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.*
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json,
            CASE
                WHEN i.AircraftInstalledPartDetailsId IS NOT NULL AND d.AircraftInstalledPartDetailsId IS NOT NULL THEN 'U'
                WHEN i.AircraftInstalledPartDetailsId IS NOT NULL AND d.AircraftInstalledPartDetailsId IS NULL     THEN 'I'
                WHEN i.AircraftInstalledPartDetailsId IS NULL     AND d.AircraftInstalledPartDetailsId IS NOT NULL THEN 'D'
            END AS Action,
            (SELECT COALESCE(i.AircraftInstalledPartDetailsId, d.AircraftInstalledPartDetailsId) AS AircraftInstalledPartDetailsId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.AircraftInstalledPartDetailsId = d.AircraftInstalledPartDetailsId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.AircraftInstalledPartDetailsId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'AircraftInstalledPartDetails'
                AND ign.ColumnName = N'AircraftInstalledPartDetailsId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.AircraftInstalledPartDetailsId,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'AircraftInstalledPartDetails'
                AND ign.ColumnName = N'AircraftInstalledPartDetailsId'
        )),
    merged AS (
        SELECT
            COALESCE(n.PKJson, o.PKJson) AS PKJson,
            COALESCE(n.ColumnName, o.ColumnName) AS ColumnName,
            o.OldValue,
            n.NewValue,
            p.Action
        FROM paired p
        LEFT JOIN oldv o
            ON o.AircraftInstalledPartDetailsId = p.AircraftInstalledPartDetailsId
        LEFT JOIN newv n
            ON n.AircraftInstalledPartDetailsId = p.AircraftInstalledPartDetailsId
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
            ON n.AircraftInstalledPartDetailsId = p.AircraftInstalledPartDetailsId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.AircraftInstalledPartDetailsId = p.AircraftInstalledPartDetailsId
                AND o2.ColumnName = n.ColumnName
            )
    ),
    installflighthoursminute_changes AS (
        SELECT pkjson,
               'InstallFlightHoursMinutes' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'InstallFlightHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'InstallFlightTime' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'InstallFlightHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'InstallFlightTime' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'InstallFlightHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'InstallFlightTime' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'InstallFlightHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'InstallFlightTime' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('InstallFlightHours', 'InstallFlightTime')
        GROUP BY pkjson, action
    ),
    limitsflighthoursminute_changes AS (
        SELECT pkjson,
               'LimitsFlightHoursMinutes' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'PartFlightHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'PartFlightHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'PartFlightHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'PartFlightHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('PartFlightHours', 'PartFlightMinutes')
        GROUP BY pkjson, action
    ),
    recordedhourminutes_changes AS (
        SELECT pkjson,
               'FlightHoursRecorded' AS columnname,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'FlightHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'FlightMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'FlightMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('FlightHours', 'FlightMinutes')
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
        FROM merged
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
        FROM merged
        WHERE columnname NOT IN (
            'InstallFlightHours',
            'InstallFlightTime',
            'PartFlightHours',
            'PartFlightMinutes',

            'FlightHours',
            'FlightMinutes',

            'FlightHoursRemainingHours',
            'FlightHoursRemainingMinutes'
        )
    ),
    all_changes AS (
        SELECT * FROM installflighthoursminute_changes
        UNION ALL
        SELECT * FROM limitsflighthoursminute_changes
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
        N'AircraftInstalledPartDetails' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
         CASE            
            WHEN m.ColumnName = 'ATAChapterId' THEN NULLIF(CONCAT_WS(' - ', NULLIF(imamOld.Level1, ''), NULLIF(imamOld.Level2, ''), NULLIF(imamOld.Level3, '')), '')
            --WHEN m.ColumnName = 'ConditionId' THEN cOld.[Description]
            WHEN m.ColumnName = 'StockLineId' THEN stOld.StockLineNumber 
            ELSE m.OldValue
        END AS OldValue,
        CASE
            WHEN m.ColumnName = 'ATAChapterId' THEN NULLIF(CONCAT_WS(' - ', NULLIF(imamNew.Level1, ''), NULLIF(imamNew.Level2, ''), NULLIF(imamNew.Level3, '')), '')
            --WHEN m.ColumnName = 'ConditionId' THEN cNew.[Description]          
            WHEN m.ColumnName = 'StockLineId' THEN stNew.StockLineNumber
            ELSE m.NewValue
        END AS NewValue
    FROM all_changes m
    LEFT JOIN dbo.ItemMasterAircraftMapping imamOld WITH(NOLOCK) ON m.ColumnName = 'ATAChapterId' AND TRY_CAST(m.OldValue AS BIGINT) = imamOld.ItemMasterAircraftMappingId
    LEFT JOIN dbo.ItemMasterAircraftMapping imamNew WITH(NOLOCK) ON m.ColumnName = 'ATAChapterId' AND TRY_CAST(m.NewValue AS BIGINT) = imamNew.ItemMasterAircraftMappingId
    LEFT JOIN dbo.Stockline stOld WITH(NOLOCK) ON m.ColumnName = 'StockLineId' AND TRY_CAST(m.OldValue AS BIGINT) = stOld.StockLineId
    LEFT JOIN dbo.Stockline stNew WITH(NOLOCK) ON m.ColumnName = 'StockLineId' AND TRY_CAST(m.NewValue AS BIGINT) = stNew.StockLineId
    --LEFT JOIN dbo.Condition cOld WITH(NOLOCK) ON m.ColumnName = 'ConditionId' AND TRY_CAST(m.OldValue AS BIGINT) = cOld.ConditionId
    --LEFT JOIN dbo.Condition cNew WITH(NOLOCK) ON m.ColumnName = 'ConditionId' AND TRY_CAST(m.NewValue AS BIGINT) = cNew.ConditionId
    WHERE 
        m.ColumnName <> 'AircraftInstalledPartDetailsId' and (
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
