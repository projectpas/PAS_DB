CREATE TABLE [dbo].[ManualJournalDetailsAudit] (
    [AuditManualJournalDetailsId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ManualJournalDetailsId]      BIGINT          NOT NULL,
    [ManualJournalHeaderId]       BIGINT          NULL,
    [GlAccountId]                 BIGINT          NULL,
    [Debit]                       DECIMAL (18, 2) NULL,
    [Credit]                      DECIMAL (18, 2) NULL,
    [Description]                 VARCHAR (MAX)   NULL,
    [ManagementStructureId]       BIGINT          NULL,
    [LastMSLevel]                 VARCHAR (200)   NULL,
    [AllMSlevels]                 VARCHAR (MAX)   NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ManualJournalDetailsAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   CONSTRAINT [DF_ManualJournalDetailsAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT             CONSTRAINT [DF_ManualJournalDetailsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT             CONSTRAINT [DF_ManualJournalDetailsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ReferenceId]                 BIGINT          NULL,
    [ReferenceTypeId]             INT             NULL,
    [IsClosed]                    BIT             NULL,
    CONSTRAINT [PK_ManualJournalDetailsAudit] PRIMARY KEY CLUSTERED ([AuditManualJournalDetailsId] ASC)
);



