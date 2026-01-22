CREATE TABLE [dbo].[ApprovalAmountAudit] (
    [ApprovalAmountAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ApprovalAmountId]      BIGINT         NOT NULL,
    [Name]                  VARCHAR (100)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    CONSTRAINT [PK_ApprovalAmountAudit] PRIMARY KEY CLUSTERED ([ApprovalAmountAuditId] ASC)
);

