CREATE TABLE [dbo].[ApprovalRule] (
    [ApprovalRuleId]        BIGINT          IDENTITY (1, 1) NOT NULL,
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
    [IsActive]              BIT             CONSTRAINT [ApprovalRules_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [ApprovalRules_DC_Delete] DEFAULT ((0)) NOT NULL,
    [RoleId]                BIGINT          NULL,
    CONSTRAINT [PK_ApprovalRules] PRIMARY KEY CLUSTERED ([ApprovalRuleId] ASC),
    CONSTRAINT [FK_ApprovalRules_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO


CREATE TRIGGER [dbo].[Trg_ApprovalRule]

   ON  [dbo].[ApprovalRule]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[ApprovalRuleAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END