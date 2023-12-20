CREATE TABLE [dbo].[LegalEntityDocumentDetailsAudit] (
    [AuditLegalEntityDocumentDetailId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [LegalEntityDocumentDetailId]      BIGINT         NOT NULL,
    [LegalEntityId]                    BIGINT         NOT NULL,
    [AttachmentId]                     BIGINT         NOT NULL,
    [DocName]                          VARCHAR (100)  NULL,
    [DocMemo]                          NVARCHAR (MAX) NULL,
    [DocDescription]                   VARCHAR (100)  NULL,
    [MasterCompanyId]                  INT            NOT NULL,
    [CreatedBy]                        VARCHAR (256)  NULL,
    [UpdatedBy]                        VARCHAR (256)  NULL,
    [CreatedDate]                      DATETIME2 (7)  NULL,
    [UpdatedDate]                      DATETIME2 (7)  NULL,
    [IsActive]                         BIT            NULL,
    [IsDeleted]                        BIT            NULL,
    CONSTRAINT [PK_LegalEntityDocumentDetailsAudit] PRIMARY KEY CLUSTERED ([AuditLegalEntityDocumentDetailId] ASC)
);

