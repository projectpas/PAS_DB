CREATE TABLE [dbo].[TaskStatusAudit] (
    [TaskStatusAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [TaskStatusId]      BIGINT         NOT NULL,
    [Description]       VARCHAR (200)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NULL,
    [CreatedBy]         VARCHAR (256)  NULL,
    [UpdatedBy]         VARCHAR (256)  NULL,
    [CreatedDate]       DATETIME2 (7)  NULL,
    [UpdatedDate]       DATETIME2 (7)  NULL,
    [IsActive]          BIT            NULL,
    [IsDeleted]         BIT            NULL,
    [StatusCode]        VARCHAR (25)   NULL,
    PRIMARY KEY CLUSTERED ([TaskStatusAuditId] ASC)
);

