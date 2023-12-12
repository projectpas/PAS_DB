CREATE TABLE [dbo].[InvoiceCheckPayment] (
    [CheckPaymentId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceiptId]       BIGINT          NOT NULL,
    [CustomerId]      BIGINT          NOT NULL,
    [PaymentMethod]   VARCHAR (50)    NULL,
    [CheckDate]       DATETIME        NOT NULL,
    [Amount]          DECIMAL (20, 2) NOT NULL,
    [CurrencyId]      INT             NOT NULL,
    [CheckNumber]     VARCHAR (50)    NOT NULL,
    [PayorsBank]      VARCHAR (50)    NULL,
    [BankAccount]     INT             NULL,
    [GLAccountNumber] BIGINT          NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF_InvoiceCheckPayment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [DF_InvoiceCheckPayment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [DF__InvoiceCh__IsAct__3E7C9307] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [DF__InvoiceCh__IsDel__3F70B740] DEFAULT ((0)) NOT NULL,
    [PageIndex]       INT             NULL,
    [Ismiscellaneous] BIT             DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_InvoiceCheckPayment] PRIMARY KEY CLUSTERED ([CheckPaymentId] ASC),
    CONSTRAINT [FK_InvoiceCheckPayment_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_InvoiceCheckPayment_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_InvoiceCheckPayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_InvoiceCheckPaymentAudit]

   ON  [dbo].[InvoiceCheckPayment]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO InvoiceCheckPaymentAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END