CREATE TABLE [dbo].[WorksheetPart] (
    [WorksheetPartId]        BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorksheetHeaderId]      BIGINT         NOT NULL,
    [ItemNo]                 VARCHAR (10)   NULL,
    [SignedBy]               VARCHAR (100)  NULL,
    [DefectDescription]      VARCHAR (500)  NULL,
    [MaintenanceAction]      VARCHAR (2000) NULL,
    [MaintenanceTime]        VARCHAR (20)   NULL,
    [MechBy]                 BIGINT         NULL,
    [InspBy]                 BIGINT         NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF_WorksheetPart_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_WorksheetPart_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]              VARCHAR (256)  DEFAULT ('') NOT NULL,
    [UpdatedBy]              VARCHAR (256)  DEFAULT ('') NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_WorksheetPart_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_WorksheetPart_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [SignedById]             BIGINT         NULL,
    [MaintenanceTimeMinutes] INT            NULL,
    CONSTRAINT [PK_WorksheetPart] PRIMARY KEY CLUSTERED ([WorksheetPartId] ASC),
    CONSTRAINT [FK_WorksheetPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

GO
CREATE TRIGGER [dbo].[trg_Audit_dbo_WorksheetPart]
ON [dbo].[WorksheetPart]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    ;WITH
    d AS (SELECT d.[WorksheetPartId],d.[WorksheetHeaderId],d.[ItemNo],d.[SignedBy],d.[DefectDescription],d.[MaintenanceAction],d.[MaintenanceTime],d.[MechBy],d.[InspBy],d.[MasterCompanyId],d.[IsActive],d.[IsDeleted],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[SignedById],d.[MaintenanceTimeMinutes] FROM deleted d),
    i AS (SELECT i.[WorksheetPartId],i.[WorksheetHeaderId],i.[ItemNo],i.[SignedBy],i.[DefectDescription],i.[MaintenanceAction],i.[MaintenanceTime],i.[MechBy],i.[InspBy],i.[MasterCompanyId],i.[IsActive],i.[IsDeleted],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[SignedById],i.[MaintenanceTimeMinutes] FROM inserted i),
    paired AS (
        SELECT
            COALESCE(i.WorksheetPartId, d.WorksheetPartId) AS WorksheetPartId,
            (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
            (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json,
            CASE
                WHEN i.WorksheetPartId IS NOT NULL AND d.WorksheetPartId IS NOT NULL THEN 'U'
                WHEN i.WorksheetPartId IS NOT NULL AND d.WorksheetPartId IS NULL THEN 'I'
                WHEN i.WorksheetPartId IS NULL AND d.WorksheetPartId IS NOT NULL THEN 'D'
            END AS Action,
            (SELECT COALESCE(i.WorksheetPartId, d.WorksheetPartId) AS WorksheetPartId
                FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
        FROM d
        FULL OUTER JOIN i
            ON i.WorksheetPartId = d.WorksheetPartId
    ),
    oldv AS (
        SELECT
            p.PKJson,
            p.WorksheetPartId,
            v.[key] AS ColumnName,
            v.value AS OldValue
        FROM paired p
        CROSS APPLY OPENJSON(p.old_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName = N'WorksheetPart'
                AND ign.ColumnName = N'WorksheetPartId'
        )
    ),
    newv AS (
        SELECT
            p.PKJson,
            p.WorksheetPartId,
            v.[key] AS ColumnName,
            v.value AS NewValue
        FROM paired p
        CROSS APPLY OPENJSON(p.new_row_json) v
        WHERE NOT EXISTS (
            SELECT 1
            FROM dbo.IgnoreColumn ign WITH(NOLOCK)
            WHERE ign.SchemaName = N'dbo'
                AND ign.TableName = N'WorksheetPart'
                AND ign.ColumnName = N'WorksheetPartId'
        )
    ),
    merged AS (
        SELECT
            COALESCE(n.PKJson, o.PKJson) AS PKJson,
            COALESCE(n.ColumnName, o.ColumnName) AS ColumnName,
            o.OldValue,
            n.NewValue,
            p.Action
        FROM paired p
        LEFT JOIN oldv o
            ON o.WorksheetPartId = p.WorksheetPartId
        LEFT JOIN newv n
            ON n.WorksheetPartId = p.WorksheetPartId
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
            ON n.WorksheetPartId = p.WorksheetPartId
        WHERE NOT EXISTS (
            SELECT 1
            FROM oldv o2
            WHERE o2.WorksheetPartId = p.WorksheetPartId
                AND o2.ColumnName = n.ColumnName
        )
    )
    INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
    SELECT
        N'dbo' AS SchemaName,
        N'WorksheetPart' AS TableName,
        m.PKJson,
        m.ColumnName,
        m.Action,
        CASE
            WHEN m.ColumnName = 'SignedById' THEN TRIM(CONCAT(eOld.FirstName, ' ', eOld.LastName))
            ELSE m.OldValue
        END AS OldValue,
        CASE
            WHEN m.ColumnName = 'SignedById' THEN TRIM(CONCAT(eNew.FirstName, ' ', eNew.LastName))
            ELSE m.NewValue
        END AS NewValue
    FROM merged m
    LEFT JOIN [dbo].[Employee] eOld WITH(NOLOCK) ON m.ColumnName = 'SignedById' AND TRY_CAST(m.OldValue AS BIGINT) = eOld.EmployeeId
    LEFT JOIN [dbo].[Employee] eNew WITH(NOLOCK) ON m.ColumnName = 'SignedById' AND TRY_CAST(m.NewValue AS BIGINT) = eNew.EmployeeId
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

