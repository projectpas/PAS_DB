CREATE TABLE [dbo].[WorkOrderDocumentsAudit] (
    [WorkOrderDocumentAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderDocumentId]      BIGINT         NOT NULL,
    [WorkOrderId]              BIGINT         NOT NULL,
    [WorkFlowWorkOrderId]      BIGINT         NOT NULL,
    [AttachmentId]             BIGINT         NOT NULL,
    [Name]                     VARCHAR (100)  NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [Description]              VARCHAR (100)  NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  NOT NULL,
    [IsActive]                 BIT            NOT NULL,
    [IsDeleted]                BIT            NOT NULL,
    [TypeId]                   BIGINT         NOT NULL,
    [WOPartNoId]               BIGINT         NOT NULL,
    CONSTRAINT [PK_WorkOrderDocumentsAudit] PRIMARY KEY CLUSTERED ([WorkOrderDocumentAuditId] ASC)
);

