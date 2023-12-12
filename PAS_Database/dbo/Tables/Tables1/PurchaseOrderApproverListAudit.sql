CREATE TABLE [dbo].[PurchaseOrderApproverListAudit] (
    [PurchaseOrderApproverListAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [POApproverListId]                 BIGINT        NOT NULL,
    [POApproverId]                     BIGINT        NOT NULL,
    [EmployeeId]                       BIGINT        NOT NULL,
    [Level]                            INT           NOT NULL,
    [StatusId]                         INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_PurchaseOrderApproverListAudit] PRIMARY KEY CLUSTERED ([PurchaseOrderApproverListAuditId] ASC)
);

