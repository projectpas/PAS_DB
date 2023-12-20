CREATE TABLE [dbo].[ApprovalStatusAudit] (
    [AuditApprovalStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ApprovalStatusId]      INT           NOT NULL,
    [Name]                  VARCHAR (50)  NOT NULL,
    [Description]           VARCHAR (250) NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (50)  NOT NULL,
    [CreatedDate]           DATETIME      NOT NULL,
    [UpdatedBy]             VARCHAR (50)  NULL,
    [UpdatedDate]           DATETIME      NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    CONSTRAINT [PK_ApprovalStatusAudit] PRIMARY KEY CLUSTERED ([AuditApprovalStatusId] ASC)
);

