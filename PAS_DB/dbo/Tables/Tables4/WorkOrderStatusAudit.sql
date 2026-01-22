CREATE TABLE [dbo].[WorkOrderStatusAudit] (
    [AuditWOStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Id]              BIGINT         NOT NULL,
    [Description]     VARCHAR (MAX)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [Status]          VARCHAR (256)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [StatusCode]      NVARCHAR (50)  NULL,
    CONSTRAINT [PK_WorkOrderStatusAudit] PRIMARY KEY CLUSTERED ([AuditWOStatusId] ASC)
);

