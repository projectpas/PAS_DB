CREATE TABLE [dbo].[InvoiceCreditDebitCardPaymentAudit] (
    [CreditDebitPaymentAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [CreditDebitPaymentId]      BIGINT          NOT NULL,
    [ReceiptId]                 BIGINT          NULL,
    [CustomerId]                BIGINT          NOT NULL,
    [PaymentDate]               DATETIME        NOT NULL,
    [Amount]                    DECIMAL (20, 2) NOT NULL,
    [Reference]                 VARCHAR (50)    NULL,
    [CurrencyId]                INT             NOT NULL,
    [CardNumber]                VARCHAR (20)    NOT NULL,
    [CardTypeId]                BIGINT          NOT NULL,
    [ExpirationDate]            DATETIME        NOT NULL,
    [SecurityCode]              VARCHAR (50)    NOT NULL,
    [CardholderName]            VARCHAR (100)   NOT NULL,
    [BillingAddress]            VARCHAR (200)   NULL,
    [PhoneNo]                   VARCHAR (20)    NULL,
    [ApprovalRef]               VARCHAR (50)    NULL,
    [GLAccountNumber]           BIGINT          NOT NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    [PageIndex]                 INT             NULL,
    [PostalCode]                VARCHAR (50)    NULL,
    [Ismiscellaneous]           BIT             NULL,
    CONSTRAINT [PK_InvoiceCreditDebitCardPaymentAudit] PRIMARY KEY CLUSTERED ([CreditDebitPaymentAuditId] ASC)
);



