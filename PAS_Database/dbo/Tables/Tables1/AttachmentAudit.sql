CREATE TABLE [dbo].[AttachmentAudit] (
    [AttachmentAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [AttachmentId]      BIGINT        NOT NULL,
    [ModuleId]          INT           NOT NULL,
    [ReferenceId]       BIGINT        NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NULL,
    [CreatedDate]       DATETIME2 (7) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NULL,
    [UpdatedDate]       DATETIME2 (7) NOT NULL,
    [IsActive]          BIT           NULL,
    [IsDeleted]         BIT           NULL,
    CONSTRAINT [PK_AttachmentAudit] PRIMARY KEY CLUSTERED ([AttachmentAuditId] ASC)
);

