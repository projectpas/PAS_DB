CREATE TABLE [dbo].[CommonDocumentDetailsAudit] (
    [CommonDocumentDetailAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CommonDocumentDetailId]      BIGINT         NOT NULL,
    [ModuleId]                    INT            NOT NULL,
    [ReferenceId]                 BIGINT         NULL,
    [AttachmentId]                BIGINT         NOT NULL,
    [DocName]                     VARCHAR (100)  NULL,
    [DocMemo]                     NVARCHAR (MAX) NULL,
    [DocDescription]              VARCHAR (MAX)  NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  NOT NULL,
    [IsActive]                    BIT            NOT NULL,
    [IsDeleted]                   BIT            NOT NULL,
    [DocumentTypeId]              BIGINT         NULL,
    [ExpirationDate]              DATETIME2 (7)  NULL,
    [ReferenceIndex]              INT            NULL,
    [ModuleType]                  CHAR (2)       DEFAULT (NULL) NULL,
    CONSTRAINT [PK_CommonDocumentDetailsAudit] PRIMARY KEY CLUSTERED ([CommonDocumentDetailAuditId] ASC)
);

