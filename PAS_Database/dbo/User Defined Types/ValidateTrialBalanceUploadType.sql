CREATE TYPE [dbo].[ValidateTrialBalanceUploadType] AS TABLE (
    [GlAccountId]     BIGINT          NULL,
    [AccountCode]     VARCHAR (50)    NULL,
    [Debit]           DECIMAL (18, 2) NULL,
    [Credit]          DECIMAL (18, 2) NULL,
    [TransactionDate] VARCHAR (50)    NULL,
    [EntryDate]       VARCHAR (50)    NULL);

