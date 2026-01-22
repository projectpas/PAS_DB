CREATE TABLE [dbo].[ApprovalRuleNo] (
    [ApprovalRuleNoId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RuleNo]           INT            NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [DF_ApprovalRuleNo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [DF_ApprovalRuleNo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            CONSTRAINT [ApprovalRuleNos_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [ApprovalRuleNos_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ApprovalRuleNo] PRIMARY KEY CLUSTERED ([ApprovalRuleNoId] ASC)
);

