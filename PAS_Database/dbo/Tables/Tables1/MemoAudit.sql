CREATE TABLE [dbo].[MemoAudit] (
    [MemoAuditId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [MemoId]          BIGINT         NOT NULL,
    [MemoCode]        VARCHAR (50)   NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [ModuleId]        INT            NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [WorkOrderPartNo] BIGINT         NULL,
    CONSTRAINT [PK_MemoAudit] PRIMARY KEY CLUSTERED ([MemoAuditId] ASC)
);

