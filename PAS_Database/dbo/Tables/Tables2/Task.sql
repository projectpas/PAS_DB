CREATE TABLE [dbo].[Task] (
    [TaskId]            BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]       VARCHAR (500)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [UpdatedBy]         VARCHAR (256)  NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_Task_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_Task_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]          BIT            DEFAULT ((1)) NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_Task_IsDeleted] DEFAULT ((0)) NULL,
    [Sequence]          BIGINT         NOT NULL,
    [IsTravelerTask]    BIT            NULL,
    [Descrepancy]       NVARCHAR (MAX) NULL,
    [Resolution]        NVARCHAR (MAX) NULL,
    [StandardHours]     INT            NULL,
    [StandardMinute]    INT            NULL,
    [IsPrintInWO]       BIT            NULL,
    [IsPrintInWOQ]      BIT            NULL,
    [IsPrintInspector]  BIT            NULL,
    [IsPrintTechnician] BIT            NULL,
    [IsPrintAdmin]      BIT            NULL,
    PRIMARY KEY CLUSTERED ([TaskId] ASC)
);














GO


CREATE TRIGGER [dbo].[Trg_TaskAudit] ON [dbo].[Task]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[TaskAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END
GO
  CREATE     TRIGGER [dbo].[trg_Audit_dbo_Task]
        ON [dbo].[Task]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[TaskId],d.[Description],d.[Memo],d.[MasterCompanyId],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[Sequence],d.[IsTravelerTask],d.[Descrepancy],d.[Resolution],d.[StandardHours],d.[StandardMinute],d.[IsPrintInWO],d.[IsPrintInWOQ],d.[IsPrintInspector],d.[IsPrintTechnician],d.[IsPrintAdmin] FROM deleted d),
            i AS (SELECT i.[TaskId],i.[Description],i.[Memo],i.[MasterCompanyId],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[Sequence],i.[IsTravelerTask],i.[Descrepancy],i.[Resolution],i.[StandardHours],i.[StandardMinute],i.[IsPrintInWO],i.[IsPrintInWOQ],i.[IsPrintInspector],i.[IsPrintTechnician],i.[IsPrintAdmin] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.TaskId, d.TaskId ) AS TaskId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.TaskId IS NOT NULL AND d.TaskId IS NOT NULL THEN 'U'
                        WHEN i.TaskId IS NOT NULL AND d.TaskId IS NULL     THEN 'I'
                        WHEN i.TaskId IS NULL     AND d.TaskId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.TaskId, d.TaskId) AS TaskId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.TaskId = d.TaskId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.TaskId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Task'
                      AND ign.ColumnName = N'TaskId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.TaskId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign WITH(NOLOCK)
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'Task'
                      AND ign.ColumnName = N'TaskId'
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
                    ON o.TaskId = p.TaskId
                LEFT JOIN newv n
                    ON n.TaskId = p.TaskId
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
                    ON n.TaskId = p.TaskId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.TaskId = p.TaskId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'Task' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
            FROM merged m
            WHERE
                m.ColumnName <> 'taskId' and (
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