CREATE TABLE [dbo].[SalesOrderQuoteApproverListAudit] (
    [SalesOrderQuoteApproverListAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteApproverListId]      BIGINT        NOT NULL,
    [SalesOrderQuoteId]                  BIGINT        NULL,
    [EmployeeId]                         BIGINT        NULL,
    [Level]                              INT           NULL,
    [StatusId]                           INT           NULL,
    [MasterCompanyId]                    INT           NULL,
    [CreatedBy]                          VARCHAR (256) NULL,
    [UpdatedBy]                          VARCHAR (256) NULL,
    [CreatedDate]                        DATETIME2 (7) NULL,
    [UpdatedDate]                        DATETIME2 (7) NULL,
    CONSTRAINT [PK_SalesOrderQuoteApproverListAudit] PRIMARY KEY CLUSTERED ([SalesOrderQuoteApproverListAuditId] ASC)
);

