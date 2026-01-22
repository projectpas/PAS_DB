CREATE TABLE [dbo].[LedgerAudit] (
    [LedgerAuditId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [LedgerId]        BIGINT         NOT NULL,
    [LedgerName]      VARCHAR (50)   NOT NULL,
    [LegalEntityId]   BIGINT         NULL,
    [Description]     VARCHAR (250)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_LedgerAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_LedgerAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_LedgerAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_LedgerAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LedgerAudit] PRIMARY KEY CLUSTERED ([LedgerAuditId] ASC)
);

