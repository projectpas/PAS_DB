CREATE TABLE [dbo].[Approver] (
    [ApproverId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]      BIGINT        NOT NULL,
    [ApprovalRuleId]  BIGINT        NOT NULL,
    [IsPrimary]       BIT           CONSTRAINT [DF_Approver_IsPrimary] DEFAULT ((0)) NOT NULL,
    [SeqNo]           INT           NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_Approver_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_Approver_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Approver] PRIMARY KEY CLUSTERED ([ApproverId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ApproverAudit]

   ON  [dbo].[Approver]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ApproverAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END