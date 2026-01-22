CREATE TABLE [dbo].[SubWorkOrderDocumentsAudit] (
    [SubWorkOrderDocumentAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SubWorkOrderDocumentId]      BIGINT         NOT NULL,
    [WorkOrderId]                 BIGINT         NOT NULL,
    [SubWorkOrderId]              BIGINT         NOT NULL,
    [SubWOPartNoId]               BIGINT         NOT NULL,
    [AttachmentId]                BIGINT         NOT NULL,
    [Name]                        VARCHAR (100)  NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [Description]                 VARCHAR (250)  NULL,
    [TypeId]                      BIGINT         NOT NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  NOT NULL,
    [IsActive]                    BIT            NOT NULL,
    [IsDeleted]                   BIT            NOT NULL,
    CONSTRAINT [PK_SubWorkOrderDocumentsAudit] PRIMARY KEY CLUSTERED ([SubWorkOrderDocumentAuditId] ASC)
);

