CREATE TYPE [dbo].[SaveTrialBalanceUploadType] AS TABLE (
    [GlAccountId]     BIGINT          NULL,
    [AccountCode]     VARCHAR (50)    NULL,
    [Debit]           DECIMAL (18, 6) NULL,
    [Credit]          DECIMAL (18, 6) NULL,
    [TransactionDate] DATETIME2 (7)   NULL,
    [EntryDate]       DATETIME2 (7)   NULL,
    [CreatedBy]       VARCHAR (256)   NULL,
    [UpdatedBy]       VARCHAR (256)   NULL,
    [EmployeeId]      BIGINT          NULL,
    [MasterCompanyId] INT             NULL,
    [LastMSLevel]     VARCHAR (200)   NULL,
    [AllMSlevels]     VARCHAR (MAX)   NULL);

