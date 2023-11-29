CREATE TABLE [dbo].[ApprovalRuleAudit] (
    [ApprovalRuleAuditId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [ApprovalRuleId]        BIGINT          NOT NULL,
    [ApprovalTaskId]        INT             NOT NULL,
    [AutoApproveId]         INT             NULL,
    [ActionId]              INT             NULL,
    [RuleNumberId]          BIGINT          NULL,
    [EntityId]              BIGINT          NULL,
    [OperatorId]            INT             NULL,
    [AmountId]              BIGINT          NULL,
    [Value]                 DECIMAL (20, 2) NULL,
    [LowerValue]            DECIMAL (20, 2) NULL,
    [UpperValue]            DECIMAL (20, 2) NULL,
    [ApproverId]            BIGINT          NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [EnforceApproval]       BIT             NULL,
    [ManagementStructureId] BIGINT          NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NOT NULL,
    [CreatedDate]           DATETIME2 (7)   NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   NOT NULL,
    [IsActive]              BIT             NOT NULL,
    [IsDeleted]             BIT             NOT NULL,
    [RoleId]                BIGINT          NULL,
    CONSTRAINT [PK_ApprovalRuleAudit] PRIMARY KEY CLUSTERED ([ApprovalRuleAuditId] ASC)
);



