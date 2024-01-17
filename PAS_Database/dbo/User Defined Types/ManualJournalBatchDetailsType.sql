CREATE TYPE [dbo].[ManualJournalBatchDetailsType] AS TABLE (
    [ManualJournalDetailsId] BIGINT          NOT NULL,
    [ManualJournalHeaderId]  BIGINT          NOT NULL,
    [GlAccountId]            BIGINT          NULL,
    [Debit]                  DECIMAL (18, 2) NULL,
    [Credit]                 DECIMAL (18, 2) NULL,
    [Description]            VARCHAR (256)   NULL,
    [ManagementStructureId]  BIGINT          NULL,
    [LastMSLevel]            VARCHAR (256)   NULL,
    [AllMSlevels]            VARCHAR (256)   NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    [ReferenceId]            BIGINT          NULL,
    [ReferenceTypeId]        INT             NULL,
    [IsReferenceChecked]     BIT             NULL);



