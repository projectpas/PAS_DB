CREATE TABLE [dbo].[MigratedARInvoice] (
    [MigratedARInvoiceId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerId]            BIGINT          NULL,
    [CustomerCode]          VARCHAR (100)   NULL,
    [CustomerName]          VARCHAR (100)   NULL,
    [WOSONumber]            VARCHAR (100)   NULL,
    [InvoiceNumber]         VARCHAR (50)    NULL,
    [InvoiceDate]           DATETIME2 (7)   NULL,
    [CreditTermsId]         INT             NULL,
    [Terms]                 VARCHAR (100)   NULL,
    [DueDate]               DATETIME2 (7)   NULL,
    [InvoiceAmount]         DECIMAL (18, 2) CONSTRAINT [DF_MigratedARInvoice_InvoiceAmount] DEFAULT ((0)) NOT NULL,
    [BalanceAmount]         DECIMAL (18, 2) CONSTRAINT [DF_MigratedARInvoice_BalanceAmount] DEFAULT ((0)) NOT NULL,
    [PaidAmount]            DECIMAL (18, 2) CONSTRAINT [DF_MigratedARInvoice_PaidAmount] DEFAULT ((0)) NOT NULL,
    [CurrencyId]            INT             NULL,
    [Currency]              VARCHAR (50)    NULL,
    [FXRate]                DECIMAL (18, 6) CONSTRAINT [DF_MigratedARInvoice_FXRate] DEFAULT ((1)) NULL,
    [ManagementStructureId] BIGINT          NULL,
    [LE]                    VARCHAR (256)   NULL,
    [DIV]                   VARCHAR (256)   NULL,
    [ReceiptNo]             VARCHAR (50)    NULL,
    [PaymentDate]           DATETIME2 (7)   NULL,
    [PaymentMethod]         VARCHAR (50)    NULL,
    [PaymentReference]      VARCHAR (100)   NULL,
    [BankAccount]           VARCHAR (200)   NULL,
    [GLAccountId]           BIGINT          NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [CreatedBy]             VARCHAR (256)   CONSTRAINT [DF_MigratedARInvoice_CreatedBy] DEFAULT ('MIGRATION') NOT NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_MigratedARInvoice_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)   CONSTRAINT [DF_MigratedARInvoice_UpdatedBy] DEFAULT ('MIGRATION') NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_MigratedARInvoice_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]              BIT             CONSTRAINT [DF_MigratedARInvoice_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_MigratedARInvoice_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SourceKey]             VARCHAR (100)   NULL,
    CONSTRAINT [PK_MigratedARInvoice] PRIMARY KEY CLUSTERED ([MigratedARInvoiceId] ASC)
);


GO
CREATE UNIQUE NONCLUSTERED INDEX [UX_MigratedARInvoice_SourceKey]
    ON [dbo].[MigratedARInvoice]([MasterCompanyId] ASC, [SourceKey] ASC) WHERE ([SourceKey] IS NOT NULL);


GO
CREATE NONCLUSTERED INDEX [IX_MigratedARInvoice_CustomerId]
    ON [dbo].[MigratedARInvoice]([CustomerId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_MigratedARInvoice_MasterCompany_Report]
    ON [dbo].[MigratedARInvoice]([MasterCompanyId] ASC, [IsActive] ASC, [IsDeleted] ASC, [BalanceAmount] ASC)
    INCLUDE([CustomerId], [ManagementStructureId], [InvoiceDate], [PaymentDate], [PaidAmount], [InvoiceAmount], [CurrencyId]);

