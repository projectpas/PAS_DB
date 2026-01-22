CREATE TABLE [dbo].[AttachmentDetailsAudit] (
    [AuditAttachmentDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AttachmentDetailId]      BIGINT          NOT NULL,
    [AttachmentId]            BIGINT          NOT NULL,
    [FileName]                VARCHAR (500)   NULL,
    [Description]             VARCHAR (MAX)   NULL,
    [Link]                    VARCHAR (500)   NULL,
    [FileFormat]              VARCHAR (500)   NULL,
    [FileSize]                DECIMAL (10, 2) NULL,
    [FileType]                VARCHAR (500)   NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NOT NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [IsActive]                BIT             NULL,
    [IsDeleted]               BIT             NULL,
    [Name]                    VARCHAR (256)   NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [TypeId]                  BIGINT          NULL,
    CONSTRAINT [PK_AttachmentDetailsAudit] PRIMARY KEY CLUSTERED ([AuditAttachmentDetailId] ASC)
);

