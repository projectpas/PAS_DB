CREATE TABLE [dbo].[CustomerTicket] (
    [CustomerTicketId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TicketID]         VARCHAR (MAX)  NULL,
    [Name]             VARCHAR (200)  NULL,
    [FromEmail]        VARCHAR (4000) NULL,
    [ToEmail]          VARCHAR (4000) NULL,
    [DepartmentId]     INT            NOT NULL,
    [PriorityId]       INT            NOT NULL,
    [Subject]          VARCHAR (MAX)  NULL,
    [EmailBody]        VARCHAR (MAX)  NULL,
    [AttachmentId]     BIGINT         NULL,
    [MasterCompanyId]  INT            NULL,
    [AssignTo]         BIGINT         NOT NULL,
    [ReportedBy]       VARCHAR (256)  NULL,
    [CreatedBy]        VARCHAR (256)  NULL,
    [UpdatedBy]        VARCHAR (256)  NULL,
    [CreatedDate]      DATETIME2 (7)  NULL,
    [UpdatedDate]      DATETIME2 (7)  NULL,
    [IsActive]         BIT            NULL,
    [IsDeleted]        BIT            NULL,
    [StatusId]         INT            NOT NULL,
    [EmployeeId]       BIGINT         NOT NULL,
    [TicketTypeId]     BIGINT         NULL
);

GO
CREATE     TRIGGER [dbo].[trg_Audit_dbo_CustomerTicket]
        ON [dbo].[CustomerTicket]
        AFTER INSERT, UPDATE, DELETE
        AS
        BEGIN
            SET NOCOUNT ON;
            ;WITH
            d AS (SELECT d.[CustomerTicketId],d.[TicketID],d.[Name],d.[FromEmail],d.[ToEmail],d.[DepartmentId],d.[PriorityId],d.[Subject],d.[EmailBody],d.[AttachmentId],d.[MasterCompanyId],d.[AssignTo],d.[ReportedBy],d.[CreatedBy],d.[UpdatedBy],d.[CreatedDate],d.[UpdatedDate],d.[IsActive],d.[IsDeleted],d.[StatusId],d.[EmployeeId] FROM deleted d),
            i AS (SELECT i.[CustomerTicketId],i.[TicketID],i.[Name],i.[FromEmail],i.[ToEmail],i.[DepartmentId],i.[PriorityId],i.[Subject],i.[EmailBody],i.[AttachmentId],i.[MasterCompanyId],i.[AssignTo],i.[ReportedBy],i.[CreatedBy],i.[UpdatedBy],i.[CreatedDate],i.[UpdatedDate],i.[IsActive],i.[IsDeleted],i.[StatusId],i.[EmployeeId] FROM inserted i),
            paired AS (
                SELECT
                    COALESCE(i.CustomerTicketId, d.CustomerTicketId ) AS CustomerTicketId,
                    (SELECT d.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS old_row_json,
                    (SELECT i.* FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS new_row_json, 
                    CASE
                        WHEN i.CustomerTicketId IS NOT NULL AND d.CustomerTicketId IS NOT NULL THEN 'U'
                        WHEN i.CustomerTicketId IS NOT NULL AND d.CustomerTicketId IS NULL     THEN 'I'
                        WHEN i.CustomerTicketId IS NULL     AND d.CustomerTicketId IS NOT NULL THEN 'D'
                    END AS Action,

                    (SELECT COALESCE(i.CustomerTicketId, d.CustomerTicketId) AS CustomerTicketId
                     FOR JSON PATH, WITHOUT_ARRAY_WRAPPER) AS PKJson
                FROM d
                FULL OUTER JOIN i
                    ON i.CustomerTicketId = d.CustomerTicketId
            ),

            oldv AS (
                SELECT
                    p.PKJson,
                    p.CustomerTicketId,
                    v.[key]  AS ColumnName,
                    v.value  AS OldValue
                FROM paired p
                CROSS APPLY OPENJSON(p.old_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CustomerTicket'
                      AND ign.ColumnName = N'CustomerTicketId'
                )),
            newv AS (
                SELECT
                    p.PKJson,
                    p.CustomerTicketId ,
                    v.[key]  AS ColumnName,
                    v.value  AS NewValue
                FROM paired p
                CROSS APPLY OPENJSON(p.new_row_json) v
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM dbo.IgnoreColumn ign
                    WHERE ign.SchemaName = N'dbo'
                      AND ign.TableName  = N'CustomerTicket'
                      AND ign.ColumnName = N'CustomerTicketId'
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
                    ON o.CustomerTicketId = p.CustomerTicketId
                LEFT JOIN newv n
                    ON n.CustomerTicketId = p.CustomerTicketId
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
                    ON n.CustomerTicketId = p.CustomerTicketId
                WHERE NOT EXISTS (
                    SELECT 1
                    FROM oldv o2
                    WHERE o2.CustomerTicketId = p.CustomerTicketId
                      AND o2.ColumnName    = n.ColumnName
                )
            )
            INSERT dbo.AuditLog (SchemaName, TableName, PKJson, ColumnName, Action, OldValue, NewValue)
            SELECT
                N'dbo' AS SchemaName,
                N'CustomerTicket' AS TableName,
                m.PKJson,
                m.ColumnName,
                m.Action,
                m.OldValue,
                m.NewValue
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
                (m.Action = 'D' AND m.OldValue IS NOT NULL);
        END;