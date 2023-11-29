CREATE TABLE [dbo].[InvoiceCheckPaymentAudit] (
    [CheckPaymentAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CheckPaymentId]      BIGINT          NOT NULL,
    [ReceiptId]           BIGINT          NOT NULL,
    [CustomerId]          BIGINT          NOT NULL,
    [PaymentMethod]       VARCHAR (50)    NULL,
    [CheckDate]           DATETIME        NOT NULL,
    [Amount]              DECIMAL (20, 2) NOT NULL,
    [CurrencyId]          INT             NOT NULL,
    [CheckNumber]         VARCHAR (50)    NOT NULL,
    [PayorsBank]          VARCHAR (50)    NULL,
    [BankAccount]         INT             NULL,
    [GLAccountNumber]     BIGINT          NOT NULL,
    [Memo]                NVARCHAR (MAX)  NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   NOT NULL,
    [IsActive]            BIT             NOT NULL,
    [IsDeleted]           BIT             NOT NULL,
    [PageIndex]           INT             NULL,
    [Ismiscellaneous]     BIT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_InvoiceCheckPaymentAudit] PRIMARY KEY CLUSTERED ([CheckPaymentAuditId] ASC)
);



