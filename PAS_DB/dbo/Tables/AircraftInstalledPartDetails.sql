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
    [PurchaseOrderNumber]            VARCHAR (50)    NULL,
    [RepairOrderNumber]              VARCHAR (50)    NULL,
    [WorksheetNumber]                VARCHAR (50)    NULL,
    [WorkOrderNum]                   VARCHAR (30)    NULL,
    [IsFromAircraft]                 BIT             NULL,
    [EngineRegistryId]               BIGINT          NULL,
    PRIMARY KEY CLUSTERED ([AircraftInstalledPartDetailsId] ASC),
    CONSTRAINT [FK_AircraftInstalledPartDetails_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);





GO
CREATE   TRIGGER [dbo].[trg_Audit_dbo_AircraftInstalledPartDetails]
ON [dbo].[AircraftInstalledPartDetails]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[AircraftInstalledPartDetailsId],d.[AircraftRegistryId],d.[ATAChapterId],d.[ItemMasterId],d.[PartNumber],d.[PartDescription],d.[IsLLP],d.[IsSerialized],d.[SerialNumber],d.[DateInstalled],d.[PositionCode],d.[Hours],d.[Minutes],d.[FlightHours],d.[Cycles],d.[Landings],d.[EngineStarts],d.[Memo],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[StockLineId],d.[ConditionId],d.[Quantity],d.[PositionCodeId],d.[SequenceNum],d.[partFlightHours],d.[partCycles],d.[partLandings],d.[partEngineStarts],d.[PartFlightMinutes],d.[FlightMinutes],d.[InstallFlightHours],d.[InstallFlightTime],d.[InstallCycles],d.[LastFlownDate],d.[PurchaseOrderNumber],d.[RepairOrderNumber],d.[WorksheetNumber],d.[WorkOrderNum] FROM deleted d),
    i AS (SELECT i.[AircraftInstalledPartDetailsId],i.[AircraftRegistryId],i.[ATAChapterId],i.[ItemMasterId],i.[PartNumber],i.[PartDescription],i.[IsLLP],i.[IsSerialized],i.[SerialNumber],i.[DateInstalled],i.[PositionCode],i.[Hours],i.[Minutes],i.[FlightHours],i.[Cycles],i.[Landings],i.[EngineStarts],i.[Memo],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[StockLineId],i.[ConditionId],i.[Quantity],i.[PositionCodeId],i.[SequenceNum],i.[partFlightHours],i.[partCycles],i.[partLandings],i.[partEngineStarts],i.[PartFlightMinutes],i.[FlightMinutes],i.[InstallFlightHours],i.[InstallFlightTime],i.[InstallCycles],i.[LastFlownDate],i.[PurchaseOrderNumber],i.[RepairOrderNumber],i.[WorksheetNumber],i.[WorkOrderNum] FROM inserted i),
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
                   WHEN MIN(CASE WHEN columnname = 'partFlightHours' THEN oldvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN oldvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'partFlightHours' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN oldvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS oldvalue,
               CASE
                   WHEN MIN(CASE WHEN columnname = 'partFlightHours' THEN newvalue END) IS NULL
                        AND MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN newvalue END) IS NULL
                   THEN NULL
                   ELSE CONCAT(CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'partFlightHours' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)), ':',
                               CAST(COALESCE(CAST(CAST(MIN(CASE WHEN columnname = 'PartFlightMinutes' THEN newvalue END) AS DECIMAL(18,6)) AS INT), 0) AS VARCHAR(10)))
               END AS newvalue,
               action
        FROM merged
        WHERE columnname IN ('partFlightHours', 'PartFlightMinutes')
        GROUP BY pkjson, action
    ),
    recordedhourminutes_changes AS (
        SELECT
            COALESCE(p.PKJson, oldRecorded.PKJson, newRecorded.PKJson) AS pkjson,
            'FlightHoursRecorded' AS columnname,
            oldRecorded.oldvalue,
            newRecorded.newvalue,
            p.action
        FROM paired p
        LEFT JOIN d
            ON d.AircraftInstalledPartDetailsId = p.AircraftInstalledPartDetailsId
        LEFT JOIN i
            ON i.AircraftInstalledPartDetailsId = p.AircraftInstalledPartDetailsId
        OUTER APPLY (
            SELECT
                p.PKJson,
                CASE
                    WHEN d.AircraftInstalledPartDetailsId IS NULL
                         OR (d.FlightHours IS NULL AND d.FlightMinutes IS NULL)
                    THEN NULL
                    ELSE CONCAT(
                        CAST(ISNULL(d.FlightHours,0) + CAST(ISNULL(d.FlightMinutes,0) AS INT) / 60 AS VARCHAR(50)),
                        ':',
                        CAST(CAST(ISNULL(d.FlightMinutes,0) AS INT) % 60 AS VARCHAR(10))
                    )
                END AS oldvalue
        ) oldRecorded
        OUTER APPLY (
            SELECT
                p.PKJson,
                CASE
                    WHEN i.AircraftInstalledPartDetailsId IS NULL
                         OR (i.FlightHours IS NULL AND i.FlightMinutes IS NULL)
                    THEN NULL
                    ELSE CONCAT(
                        CAST(ISNULL(i.FlightHours,0) + CAST(ISNULL(i.FlightMinutes,0) AS INT) / 60 AS VARCHAR(50)),
                        ':',
                        CAST(CAST(ISNULL(i.FlightMinutes,0) AS INT) % 60 AS VARCHAR(10))
                    )
                END AS newvalue
        ) newRecorded
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
    remaining_calculations AS (
        SELECT
            COALESCE(i.AircraftInstalledPartDetailsId, d.AircraftInstalledPartDetailsId) AS AircraftInstalledPartDetailsId,
            (SELECT COALESCE(i.AircraftInstalledPartDetailsId, d.AircraftInstalledPartDetailsId) AS AircraftInstalledPartDetailsId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS pkjson,
            CASE
                WHEN i.AircraftInstalledPartDetailsId IS NOT NULL AND d.AircraftInstalledPartDetailsId IS NOT NULL THEN 'U'
                WHEN i.AircraftInstalledPartDetailsId IS NOT NULL AND d.AircraftInstalledPartDetailsId IS NULL     THEN 'I'
                WHEN i.AircraftInstalledPartDetailsId IS NULL     AND d.AircraftInstalledPartDetailsId IS NOT NULL THEN 'D'
            END AS action,
            CASE
                WHEN d.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(d.PartFlightHours,0) = 0 AND ISNULL(d.PartFlightMinutes,0) = 0 THEN 0
                WHEN oldFlight.RemainingTotalMinutes < 0 THEN 0
                ELSE oldFlight.RemainingTotalMinutes / 60
            END AS OldRemainingFlightHours,
            CASE
                WHEN d.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(d.PartFlightHours,0) = 0 AND ISNULL(d.PartFlightMinutes,0) = 0 THEN 0
                WHEN oldFlight.RemainingTotalMinutes < 0 THEN 0
                ELSE oldFlight.RemainingTotalMinutes % 60
            END AS OldRemainingFlightMinutes,
            CASE
                WHEN i.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(i.PartFlightHours,0) = 0 AND ISNULL(i.PartFlightMinutes,0) = 0 THEN 0
                WHEN newFlight.RemainingTotalMinutes < 0 THEN 0
                ELSE newFlight.RemainingTotalMinutes / 60
            END AS NewRemainingFlightHours,
            CASE
                WHEN i.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(i.PartFlightHours,0) = 0 AND ISNULL(i.PartFlightMinutes,0) = 0 THEN 0
                WHEN newFlight.RemainingTotalMinutes < 0 THEN 0
                ELSE newFlight.RemainingTotalMinutes % 60
            END AS NewRemainingFlightMinutes,
            CASE
                WHEN d.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(d.PartCycles,0) > 0 THEN ISNULL(d.PartCycles,0) - ISNULL(d.InstallCycles,0) - ISNULL(d.Cycles,0)
                ELSE 0
            END AS OldRemainingCycles,
            CASE
                WHEN i.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(i.PartCycles,0) > 0 THEN ISNULL(i.PartCycles,0) - ISNULL(i.InstallCycles,0) - ISNULL(i.Cycles,0)
                ELSE 0
            END AS NewRemainingCycles,
            CASE
                WHEN d.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(d.PartLandings,0) > 0 THEN ISNULL(d.PartLandings,0) - ISNULL(d.Landings,0)
                ELSE 0
            END AS OldRemainingLandings,
            CASE
                WHEN i.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(i.PartLandings,0) > 0 THEN ISNULL(i.PartLandings,0) - ISNULL(i.Landings,0)
                ELSE 0
            END AS NewRemainingLandings,
            CASE
                WHEN d.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(d.PartEngineStarts,0) > 0 THEN ISNULL(d.PartEngineStarts,0) - ISNULL(d.EngineStarts,0)
                ELSE 0
            END AS OldRemainingEngineStarts,
            CASE
                WHEN i.AircraftInstalledPartDetailsId IS NULL THEN NULL
                WHEN ISNULL(i.PartEngineStarts,0) > 0 THEN ISNULL(i.PartEngineStarts,0) - ISNULL(i.EngineStarts,0)
                ELSE 0
            END AS NewRemainingEngineStarts
        FROM d
        FULL OUTER JOIN i
            ON i.AircraftInstalledPartDetailsId = d.AircraftInstalledPartDetailsId
        CROSS APPLY (VALUES (
            (CAST(ISNULL(d.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(d.PartFlightMinutes,0) AS INT))
            - (CAST(ISNULL(d.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(d.InstallFlightTime,0) AS INT))
            - (CAST(ISNULL(d.FlightHours,0) AS INT) * 60 + CAST(ISNULL(d.FlightMinutes,0) AS INT))
        )) oldFlight(RemainingTotalMinutes)
        CROSS APPLY (VALUES (
            (CAST(ISNULL(i.PartFlightHours,0) AS INT) * 60 + CAST(ISNULL(i.PartFlightMinutes,0) AS INT))
            - (CAST(ISNULL(i.InstallFlightHours,0) AS INT) * 60 + CAST(ISNULL(i.InstallFlightTime,0) AS INT))
            - (CAST(ISNULL(i.FlightHours,0) AS INT) * 60 + CAST(ISNULL(i.FlightMinutes,0) AS INT))
        )) newFlight(RemainingTotalMinutes)
    ),
    remaining_changes AS (
        SELECT
            rc.pkjson,
            v.columnname,
            v.oldvalue,
            v.newvalue,
            rc.action
        FROM remaining_calculations rc
        CROSS APPLY (VALUES
            ('RemainingFlightHoursMinutes',
                CASE WHEN rc.action = 'I' THEN NULL ELSE CONCAT(CAST(rc.OldRemainingFlightHours AS VARCHAR(10)), ':', CAST(rc.OldRemainingFlightMinutes AS VARCHAR(10))) END,
                CASE WHEN rc.action = 'D' THEN NULL ELSE CONCAT(CAST(rc.NewRemainingFlightHours AS VARCHAR(10)), ':', CAST(rc.NewRemainingFlightMinutes AS VARCHAR(10))) END),
            ('RemainingCycles',
                CASE WHEN rc.action = 'I' THEN NULL ELSE CAST(rc.OldRemainingCycles AS VARCHAR(50)) END,
                CASE WHEN rc.action = 'D' THEN NULL ELSE CAST(rc.NewRemainingCycles AS VARCHAR(50)) END),
            ('RemainingLandings',
                CASE WHEN rc.action = 'I' THEN NULL ELSE CAST(rc.OldRemainingLandings AS VARCHAR(50)) END,
                CASE WHEN rc.action = 'D' THEN NULL ELSE CAST(rc.NewRemainingLandings AS VARCHAR(50)) END),
            ('RemainingEngineStarts',
                CASE WHEN rc.action = 'I' THEN NULL ELSE CAST(rc.OldRemainingEngineStarts AS VARCHAR(50)) END,
                CASE WHEN rc.action = 'D' THEN NULL ELSE CAST(rc.NewRemainingEngineStarts AS VARCHAR(50)) END)
        ) v(columnname, oldvalue, newvalue)
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
            'partFlightHours',
            'PartFlightMinutes',
            'FlightHours',
            'FlightMinutes'
        )
    ),
    all_changes AS (
        SELECT * FROM installflighthoursminute_changes
        UNION ALL
        SELECT * FROM limitsflighthoursminute_changes
        UNION ALL
        SELECT * FROM recordedhourminutes_changes
        UNION ALL
        SELECT * FROM remaining_changes
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
            WHEN m.ColumnName = 'StockLineId' THEN stOld.StockLineNumber 
            ELSE m.OldValue
        END AS OldValue,
        CASE
            WHEN m.ColumnName = 'ATAChapterId' THEN NULLIF(CONCAT_WS(' - ', NULLIF(imamNew.Level1, ''), NULLIF(imamNew.Level2, ''), NULLIF(imamNew.Level3, '')), '')                   
            WHEN m.ColumnName = 'StockLineId' THEN stNew.StockLineNumber
            ELSE m.NewValue
        END AS NewValue
    FROM all_changes m
    LEFT JOIN dbo.ItemMasterAircraftMapping imamOld WITH(NOLOCK) ON m.ColumnName = 'ATAChapterId' AND TRY_CAST(m.OldValue AS BIGINT) = imamOld.ItemMasterAircraftMappingId
    LEFT JOIN dbo.ItemMasterAircraftMapping imamNew WITH(NOLOCK) ON m.ColumnName = 'ATAChapterId' AND TRY_CAST(m.NewValue AS BIGINT) = imamNew.ItemMasterAircraftMappingId
    LEFT JOIN dbo.Stockline stOld WITH(NOLOCK) ON m.ColumnName = 'StockLineId' AND TRY_CAST(m.OldValue AS BIGINT) = stOld.StockLineId
    LEFT JOIN dbo.Stockline stNew WITH(NOLOCK) ON m.ColumnName = 'StockLineId' AND TRY_CAST(m.NewValue AS BIGINT) = stNew.StockLineId   
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