CREATE TABLE [dbo].[InvoiceCreditDebitCardPayment] (
    [CreditDebitPaymentId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceiptId]            BIGINT          NULL,
    [CustomerId]           BIGINT          NOT NULL,
    [PaymentDate]          DATETIME        NOT NULL,
    [Amount]               DECIMAL (20, 2) NOT NULL,
    [Reference]            VARCHAR (50)    NULL,
    [CurrencyId]           INT             NOT NULL,
    [CardNumber]           VARCHAR (20)    NOT NULL,
    [CardTypeId]           BIGINT          NOT NULL,
    [ExpirationDate]       DATETIME        NOT NULL,
    [SecurityCode]         VARCHAR (50)    NOT NULL,
    [CardholderName]       VARCHAR (100)   NOT NULL,
    [BillingAddress]       VARCHAR (200)   NULL,
    [PhoneNo]              VARCHAR (20)    NULL,
    [ApprovalRef]          VARCHAR (50)    NULL,
    [GLAccountNumber]      BIGINT          NOT NULL,
    [Memo]                 NVARCHAR (MAX)  NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [DF_InvoiceCreditDebitCardPayment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [DF_InvoiceCreditDebitCardPayment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [DF__InvoiceCr__IsAct__4805FD41] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF__InvoiceCr__IsDel__48FA217A] DEFAULT ((0)) NOT NULL,
    [PageIndex]            INT             NULL,
    [PostalCode]           VARCHAR (50)    NULL,
    CONSTRAINT [PK_InvoiceCreditDebitCardPayment] PRIMARY KEY CLUSTERED ([CreditDebitPaymentId] ASC),
    CONSTRAINT [FK_InvoiceCreditDebitCardPayment_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_InvoiceCreditDebitCardPayment_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_InvoiceCreditDebitCardPayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




CREATE TRIGGER [dbo].[Trg_InvoiceCreditDebitCardPaymentAudit]

   ON  [dbo].[InvoiceCreditDebitCardPayment]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO InvoiceCreditDebitCardPaymentAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END