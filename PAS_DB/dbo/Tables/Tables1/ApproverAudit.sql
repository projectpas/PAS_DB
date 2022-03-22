CREATE TABLE [dbo].[ApproverAudit] (
    [ApproverAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ApproverId]      BIGINT        NOT NULL,
    [EmployeeId]      BIGINT        NOT NULL,
    [ApprovalRuleId]  BIGINT        NOT NULL,
    [IsPrimary]       BIT           NOT NULL,
    [SeqNo]           INT           NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    [RoleId]          BIGINT        NULL,
    CONSTRAINT [PK_ApproverAudit] PRIMARY KEY CLUSTERED ([ApproverAuditId] ASC)
);



