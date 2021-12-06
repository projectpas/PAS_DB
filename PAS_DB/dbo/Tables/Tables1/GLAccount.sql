CREATE TABLE [dbo].[GLAccount] (
    [GLAccountId]                 BIGINT        IDENTITY (1, 1) NOT NULL,
    [OldAccountCode]              VARCHAR (30)  NULL,
    [AccountCode]                 VARCHAR (50)  NOT NULL,
    [AccountName]                 VARCHAR (50)  NOT NULL,
    [AccountDescription]          VARCHAR (500) NULL,
    [AllowManualJE]               BIT           CONSTRAINT [GLAccount_DC_AllowManualJE] DEFAULT ((0)) NOT NULL,
    [GLAccountTypeId]             BIGINT        NOT NULL,
    [GLClassFlowClassificationId] BIGINT        NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [GLAccount_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [GLAccount_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF__GLAccount__IsAct__60A067CA] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF__GLAccount__IsDel__61948C03] DEFAULT ((0)) NOT NULL,
    [POROCategoryId]              BIGINT        NULL,
    [GLAccountNodeId]             BIGINT        NULL,
    [LedgerId]                    BIGINT        NULL,
    [LedgerName]                  VARCHAR (30)  NULL,
    [InterCompany]                BIT           CONSTRAINT [GLAccount_DC_InterCompany] DEFAULT ((0)) NOT NULL,
    [Category1099Id]              BIGINT        NULL,
    CONSTRAINT [PK_GLAccount] PRIMARY KEY CLUSTERED ([GLAccountId] ASC),
    CONSTRAINT [FK_GLAccount_Category1099Id] FOREIGN KEY ([Category1099Id]) REFERENCES [dbo].[Master1099] ([Master1099Id]),
    CONSTRAINT [FK_GLAccount_GLAccountClass] FOREIGN KEY ([GLAccountTypeId]) REFERENCES [dbo].[GLAccountClass] ([GLAccountClassId]),
    CONSTRAINT [FK_GLAccount_GLClassFlowClassification] FOREIGN KEY ([GLClassFlowClassificationId]) REFERENCES [dbo].[GLCashFlowClassification] ([GLClassFlowClassificationId]),
    CONSTRAINT [FK_GLAccount_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_GLAccount_NodeType] FOREIGN KEY ([GLAccountNodeId]) REFERENCES [dbo].[NodeType] ([NodeTypeId]),
    CONSTRAINT [FK_GLAccount_poroCategory] FOREIGN KEY ([POROCategoryId]) REFERENCES [dbo].[POROCategory] ([POROCategoryId]),
    CONSTRAINT [Unique_GLAccount] UNIQUE NONCLUSTERED ([AccountCode] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_GLAccountAudit]

   ON  [dbo].[GLAccount]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO GLAccountAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END