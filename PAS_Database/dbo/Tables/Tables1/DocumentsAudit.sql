CREATE TABLE [dbo].[DocumentsAudit] (
    [AuditDocumentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleId]        BIGINT        NOT NULL,
    [ReferenceId]     BIGINT        NOT NULL,
    [AttachmentId]    BIGINT        NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [FileName]        VARCHAR (100) NULL,
    [Description]     VARCHAR (256) NULL,
    [Link]            VARCHAR (256) NULL,
    [DocName]         VARCHAR (50)  NULL,
    [DocDescription]  VARCHAR (256) NULL,
    [DocMemo]         VARCHAR (20)  NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NULL,
    [IsDeleted]       BIT           NULL,
    CONSTRAINT [PK_DocumentAudit] PRIMARY KEY CLUSTERED ([AuditDocumentId] ASC)
);

