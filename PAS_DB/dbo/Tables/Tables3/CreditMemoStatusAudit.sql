CREATE TABLE [dbo].[CreditMemoStatusAudit] (
    [CreditMemoStatusAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Id]                      INT           NOT NULL,
    [Name]                    VARCHAR (50)  NULL,
    [Description]             VARCHAR (250) NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (50)  NOT NULL,
    [CreatedDate]             DATETIME      CONSTRAINT [DF_CreditMemoStatusAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (50)  NULL,
    [UpdatedDate]             DATETIME      CONSTRAINT [DF_CreditMemoStatusAudit_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                BIT           CONSTRAINT [DF_CreditMemoStatusAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT           CONSTRAINT [DF_CreditMemoStatusAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CreditMemoStatusAudit] PRIMARY KEY CLUSTERED ([CreditMemoStatusAuditId] ASC)
);

