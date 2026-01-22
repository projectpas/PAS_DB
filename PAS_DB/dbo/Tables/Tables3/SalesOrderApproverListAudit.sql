CREATE TABLE [dbo].[SalesOrderApproverListAudit] (
    [SalesOrderApproverListAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderApproverListId]      BIGINT        NOT NULL,
    [SalesOrderId]                  BIGINT        NOT NULL,
    [EmployeeId]                    BIGINT        NOT NULL,
    [Level]                         INT           NOT NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NOT NULL,
    [UpdatedBy]                     VARCHAR (256) NOT NULL,
    [CreatedDate]                   DATETIME2 (7) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_SalesOrderApproverListAudit] PRIMARY KEY CLUSTERED ([SalesOrderApproverListAuditId] ASC)
);

