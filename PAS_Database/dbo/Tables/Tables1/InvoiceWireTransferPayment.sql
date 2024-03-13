CREATE TABLE [dbo].[InvoiceWireTransferPayment] (
    [WireTransferId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceiptId]       BIGINT          NOT NULL,
    [CustomerId]      BIGINT          NOT NULL,
    [WireDate]        DATETIME        NOT NULL,
    [Amount]          DECIMAL (20, 2) NOT NULL,
    [CurrencyId]      INT             NOT NULL,
    [BankName]        INT             NULL,
    [ReferenceNo]     VARCHAR (100)   NULL,
    [IMAD_OMADNo]     VARCHAR (100)   NULL,
    [BankAccount]     VARCHAR (256)   NULL,
    [GLAccountNumber] BIGINT          NOT NULL,
    [Memo]            NVARCHAR (MAX)  NULL,
    [MasterCompanyId] INT             NOT NULL,
    [CreatedBy]       VARCHAR (256)   NOT NULL,
    [UpdatedBy]       VARCHAR (256)   NOT NULL,
    [CreatedDate]     DATETIME2 (7)   CONSTRAINT [DF_InvoiceWireTransferPayment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)   CONSTRAINT [DF_InvoiceWireTransferPayment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT             CONSTRAINT [DF__InvoiceWi__IsAct__5DF53E60] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT             CONSTRAINT [DF__InvoiceWi__IsDel__5EE96299] DEFAULT ((0)) NOT NULL,
    [PageIndex]       INT             NULL,
    [Ismiscellaneous] BIT             NULL,
    CONSTRAINT [PK_InvoiceWireTransfer] PRIMARY KEY CLUSTERED ([WireTransferId] ASC),
    CONSTRAINT [FK_InvoiceWireTransferPayment_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_InvoiceWireTransferPayment_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_InvoiceWireTransferPayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO




CREATE TRIGGER [dbo].[Trg_InvoiceWireTransferPaymentAudit]

   ON  [dbo].[InvoiceWireTransferPayment]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO InvoiceWireTransferPaymentAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END