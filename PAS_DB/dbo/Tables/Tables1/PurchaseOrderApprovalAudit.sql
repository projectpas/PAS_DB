CREATE TABLE [dbo].[PurchaseOrderApprovalAudit] (
    [PurchaseOrderApprovalAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderApprovalId]      BIGINT         NOT NULL,
    [PurchaseOrderId]              BIGINT         NOT NULL,
    [PurchaseOrderPartId]          BIGINT         NOT NULL,
    [Memo]                         NVARCHAR (MAX) NULL,
    [SentDate]                     DATETIME2 (7)  NULL,
    [ApprovedDate]                 DATETIME2 (7)  NULL,
    [ApprovedById]                 BIGINT         NULL,
    [ApprovedByName]               VARCHAR (200)  NULL,
    [RejectedDate]                 DATETIME2 (7)  NULL,
    [RejectedBy]                   BIGINT         NULL,
    [RejectedByName]               VARCHAR (200)  NULL,
    [StatusId]                     INT            NULL,
    [StatusName]                   VARCHAR (50)   NULL,
    [ActionId]                     INT            NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NOT NULL,
    [UpdatedBy]                    VARCHAR (256)  NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  NOT NULL,
    [IsActive]                     BIT            NOT NULL,
    [IsDeleted]                    BIT            NOT NULL,
    [InternalSentToId]             BIGINT         NULL,
    [InternalSentToName]           VARCHAR (100)  NULL,
    [InternalSentById]             BIGINT         NULL,
    CONSTRAINT [PK_PurchaseOrderApprovalAudit] PRIMARY KEY CLUSTERED ([PurchaseOrderApprovalAuditId] ASC)
);



