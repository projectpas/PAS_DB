CREATE TABLE [dbo].[WorksheetHeader] (
    [WorksheetHeaderId]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorksheetNumber]                VARCHAR (50)   NULL,
    [MakeTypeId]                     BIGINT         NOT NULL,
    [MakeType]                       VARCHAR (100)  NULL,
    [AircraftModelId]                BIGINT         NULL,
    [AircraftModel]                  VARCHAR (100)  NULL,
    [WorksheetType]                  BIGINT         NULL,
    [WorkOrderNo]                    VARCHAR (50)   NULL,
    [AFHours]                        VARCHAR (50)   NULL,
    [InspectionType]                 VARCHAR (50)   NULL,
    [InspectionDate]                 DATE           NULL,
    [QualitySafetyDeptSignOutBy]     BIGINT         NULL,
    [QualitySafetyDeptSignOutDate]   DATETIME       NULL,
    [QualitySafetyDeptSignInBy]      BIGINT         NULL,
    [QualitySafetyDeptSignInDate]    DATETIME       NULL,
    [ReleaseToServiceBy]             BIGINT         NULL,
    [ReleaseDate]                    DATETIME       NULL,
    [CreatedBy]                      VARCHAR (256)  NOT NULL,
    [CreatedDate]                    DATETIME2 (7)  CONSTRAINT [DF_WorksheetHeader_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [MasterCompanyId]                INT            NOT NULL,
    [IsActive]                       BIT            CONSTRAINT [DF_WorksheetHeader_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT            CONSTRAINT [DF_WorksheetHeader_IsDeleted] DEFAULT ((0)) NOT NULL,
    [UpdatedBy]                      VARCHAR (256)  CONSTRAINT [DF_WorksheetHeader_UpdatedBy] DEFAULT ('') NOT NULL,
    [UpdatedDate]                    DATETIME2 (7)  CONSTRAINT [DF_WorksheetHeader_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [AMONumber]                      VARCHAR (100)  NULL,
    [TechnicalRecordsWO]             VARCHAR (100)  NULL,
    [CalmSysWO]                      VARCHAR (100)  NULL,
    [AircraftReg]                    VARCHAR (50)   NULL,
    [CertificationStatement]         VARCHAR (2000) NULL,
    [ReleaseLicenseNumber]           VARCHAR (100)  NULL,
    [WorksheetTypeId]                BIGINT         NULL,
    [TailNum]                        VARCHAR (100)  NULL,
    [SerialNum]                      VARCHAR (100)  NULL,
    [AircraftInstalledPartDetailsId] BIGINT         NULL,
    [ProgramId]                      BIGINT         NULL,
    [AircraftRegistryId]             BIGINT         NULL,
    [DupInspSysDescription]          VARCHAR (100)  NULL,
    [DupInspDefectWorkNo]            VARCHAR (50)   NULL,
    [DupInspDate]                    DATE           NULL,
    [DupInspStation]                 VARCHAR (50)   NULL,
    [DupInspSignatory1By]            BIGINT         NULL,
    [DupInspSignatory1LicAppNo]      VARCHAR (50)   NULL,
    [DupInspSignatory1Time]          VARCHAR (20)   NULL,
    [DupInspSignatory2By]            BIGINT         NULL,
    [DupInspSignatory2LicAppNo]      VARCHAR (50)   NULL,
    [DupInspSignatory2Time]          VARCHAR (20)   NULL,
    [MtcCategoryId]                  BIGINT         NULL,
    [WorkSheetStatusId]              INT            NULL,
    [IsScheduled]                    BIT            NULL,
    [InspectionTypeId]               BIGINT         NULL,
    [IsFromAircraft]                 BIT            NULL,
    [EngineRegistryId]               BIGINT         NULL,
    CONSTRAINT [PK_WorksheetHeader] PRIMARY KEY CLUSTERED ([WorksheetHeaderId] ASC),
    CONSTRAINT [FK_WorksheetHeader_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_WorksheetHeader_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);








GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_WorksheetHeader]
ON [dbo].[WorksheetHeader]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[WorksheetHeaderId],d.[WorksheetNumber],d.[MakeTypeId],d.[MakeType],d.[AircraftModelId],d.[AircraftModel],d.[WorksheetType],d.[WorkOrderNo],d.[AFHours],d.[InspectionType],d.[InspectionDate],d.[QualitySafetyDeptSignOutBy],d.[QualitySafetyDeptSignOutDate],d.[QualitySafetyDeptSignInBy],d.[QualitySafetyDeptSignInDate],d.[ReleaseToServiceBy],d.[ReleaseDate],d.[CreatedBy],d.[CreatedDate],d.[MasterCompanyId],d.[IsActive],d.[IsDeleted],d.[UpdatedBy],d.[UpdatedDate],d.[AMONumber],d.[TechnicalRecordsWO],d.[CalmSysWO],d.[AircraftReg],d.[CertificationStatement],d.[ReleaseLicenseNumber],d.[WorksheetTypeId],d.[TailNum],d.[SerialNum],d.[AircraftInstalledPartDetailsId],d.[ProgramId],d.[AircraftRegistryId],d.[DupInspSysDescription],d.[DupInspDefectWorkNo],d.[DupInspDate],d.[DupInspStation],d.[DupInspSignatory1By],d.[DupInspSignatory1LicAppNo],d.[DupInspSignatory1Time],d.[DupInspSignatory2By],d.[DupInspSignatory2LicAppNo],d.[DupInspSignatory2Time],d.[MtcCategoryId],d.[WorkSheetStatusId] FROM deleted d),
    i AS (SELECT i.[WorksheetHeaderId],i.[WorksheetNumber],i.[MakeTypeId],i.[MakeType],i.[AircraftModelId],i.[AircraftModel],i.[WorksheetType],i.[WorkOrderNo],i.[AFHours],i.[InspectionType],i.[InspectionDate],i.[QualitySafetyDeptSignOutBy],i.[QualitySafetyDeptSignOutDate],i.[QualitySafetyDeptSignInBy],i.[QualitySafetyDeptSignInDate],i.[ReleaseToServiceBy],i.[ReleaseDate],i.[CreatedBy],i.[CreatedDate],i.[MasterCompanyId],i.[IsActive],i.[IsDeleted],i.[UpdatedBy],i.[UpdatedDate],i.[AMONumber],i.[TechnicalRecordsWO],i.[CalmSysWO],i.[AircraftReg],i.[CertificationStatement],i.[ReleaseLicenseNumber],i.[WorksheetTypeId],i.[TailNum],i.[SerialNum],i.[AircraftInstalledPartDetailsId],i.[ProgramId],i.[AircraftRegistryId],i.[DupInspSysDescription],i.[DupInspDefectWorkNo],i.[DupInspDate],i.[DupInspStation],i.[DupInspSignatory1By],i.[DupInspSignatory1LicAppNo],i.[DupInspSignatory1Time],i.[DupInspSignatory2By],i.[DupInspSignatory2LicAppNo],i.[DupInspSignatory2Time],i.[MtcCategoryId],i.[WorkSheetStatusId] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.WorksheetHeaderId, d.WorksheetHeaderId ) AS WorksheetHeaderId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
            CASE
                WHEN i.WorksheetHeaderId IS NOT NULL AND d.WorksheetHeaderId IS NOT NULL THEN 'U'
                WHEN i.WorksheetHeaderId IS NOT NULL AND d.WorksheetHeaderId IS NULL     THEN 'I'
                WHEN i.WorksheetHeaderId IS NULL     AND d.WorksheetHeaderId IS NOT NULL THEN 'D'
            END AS Action,

            (SELECT COALESCE(i.WorksheetHeaderId, d.WorksheetHeaderId) AS WorksheetHeaderId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.WorksheetHeaderId = d.WorksheetHeaderId
    ),

    oldv AS (
        SELECT
            p.PKJson,
            p.WorksheetHeaderId,
            v.[key]  AS ColumnName,
            v.value  AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'WorksheetHeader'
                AND ign.ColumnName = N'WorksheetHeaderId'
        )),
    newv AS (
        SELECT
            p.PKJson,
            p.WorksheetHeaderId ,
            v.[key]  AS ColumnName,
            v.value  AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName  = N'WorksheetHeader'
                AND ign.ColumnName = N'WorksheetHeaderId'
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
            ON o.WorksheetHeaderId = p.WorksheetHeaderId
        LEFT JOIN newv n
            ON n.WorksheetHeaderId = p.WorksheetHeaderId
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
            ON n.WorksheetHeaderId = p.WorksheetHeaderId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.WorksheetHeaderId = p.WorksheetHeaderId
                AND o2.ColumnName    = n.ColumnName
        )
    )
    INSERT [dbo].[AuditLog] (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'WorksheetHeader' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        CASE            
            WHEN m.ColumnName = 'WorksheetTypeId' THEN asOld.Section           
            WHEN m.ColumnName = 'MtcCategoryId' THEN mcOld.MtcCategory
            WHEN m.ColumnName = 'WorkSheetStatusId' THEN wssOld.[Status]
            ELSE m.OldValue
        END AS OldValue,
        CASE
            WHEN m.ColumnName = 'WorksheetTypeId' THEN asNew.Section
            WHEN m.ColumnName = 'MtcCategoryId' THEN mcNew.MtcCategory
            WHEN m.ColumnName = 'WorkSheetStatusId' THEN wssNew.[Status]
            ELSE m.NewValue
        END AS NewValue
    FROM merged m
    LEFT JOIN [dbo].[AircraftSection] asOld WITH(NOLOCK) ON m.ColumnName = 'WorksheetTypeId' AND TRY_CAST(m.OldValue AS BIGINT) = asOld.AircraftSectionId
    LEFT JOIN [dbo].[AircraftSection] asNew WITH(NOLOCK) ON m.ColumnName = 'WorksheetTypeId' AND TRY_CAST(m.NewValue AS BIGINT) = asNew.AircraftSectionId
    LEFT JOIN [dbo].[MaintenanceCategory] mcOld WITH(NOLOCK) ON m.ColumnName = 'MtcCategoryId' AND TRY_CAST(m.OldValue AS BIGINT) = mcOld.MtcCategoryId
    LEFT JOIN [dbo].[MaintenanceCategory] mcNew WITH(NOLOCK) ON m.ColumnName = 'MtcCategoryId' AND TRY_CAST(m.NewValue AS BIGINT) = mcNew.MtcCategoryId
    LEFT JOIN [dbo].[WorkSheetStatus] wssOld WITH(NOLOCK) ON m.ColumnName = 'WorkSheetStatusId' AND TRY_CAST(m.OldValue AS BIGINT) = wssOld.WorkSheetStatusId
    LEFT JOIN [dbo].[WorkSheetStatus] wssNew WITH(NOLOCK) ON m.ColumnName = 'WorkSheetStatusId' AND TRY_CAST(m.NewValue AS BIGINT) = wssNew.WorkSheetStatusId
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