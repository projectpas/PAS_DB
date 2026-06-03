CREATE TYPE [dbo].[ValidateTrialBalanceUploadType] AS TABLE (
    [GlAccountId]     BIGINT          NULL,
    [AccountCode]     VARCHAR (50)    NULL,
    [Debit]           DECIMAL (18, 2) NULL,
    [Credit]          DECIMAL (18, 2) NULL,
    [TransactionDate] DATETIME2 (7)   NULL,
    [EntryDate]       DATETIME2 (7)   NULL);

