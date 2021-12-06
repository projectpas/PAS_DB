CREATE TABLE [dbo].[InvoicePayments] (
    [PaymentId]                           BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerId]                          BIGINT          NOT NULL,
    [SOBillingInvoicingId]                BIGINT          NOT NULL,
    [ReceiptId]                           BIGINT          NOT NULL,
    [IsMultiplePaymentMethod]             BIT             NOT NULL,
    [IsCheckPayment]                      BIT             NULL,
    [IsWireTransfer]                      BIT             NULL,
    [IsEFT]                               BIT             NULL,
    [IsCCDCPayment]                       BIT             NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [PaymentAmount]                       DECIMAL (20, 2) NULL,
    [DiscAmount]                          DECIMAL (20, 2) NULL,
    [DiscType]                            INT             NULL,
    [BankFeeAmount]                       DECIMAL (20, 2) NULL,
    [BankFeeType]                         INT             NULL,
    [OtherAdjustAmt]                      DECIMAL (20, 2) NULL,
    [Reason]                              VARCHAR (50)    NULL,
    [RemainingBalance]                    DECIMAL (20, 2) NULL,
    [Status]                              VARCHAR (50)    NULL,
    [CreatedBy]                           VARCHAR (256)   NOT NULL,
    [UpdatedBy]                           VARCHAR (256)   NOT NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_InvoicePayments_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_InvoicePayments_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                            BIT             CONSTRAINT [DF__InvoicePa__IsAct__78A9349C] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT             CONSTRAINT [DF__InvoicePa__IsDel__799D58D5] DEFAULT ((0)) NOT NULL,
    [IsDeposite]                          BIT             NULL,
    [IsTradeReceivable]                   BIT             NULL,
    [TradeReceivableORMiscReceiptGLAccnt] BIGINT          NULL,
    [CtrlNum]                             VARCHAR (50)    NULL,
    CONSTRAINT [PK_InvoicePayments] PRIMARY KEY CLUSTERED ([PaymentId] ASC),
    CONSTRAINT [FK_InvoicePayments_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_InvoicePayments_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_InvoicePayments_SalesOrderBillingInvoicing] FOREIGN KEY ([SOBillingInvoicingId]) REFERENCES [dbo].[SalesOrderBillingInvoicing] ([SOBillingInvoicingId])
);


GO




CREATE TRIGGER [dbo].[Trg_InvoicePaymentsAudit]

   ON  [dbo].[InvoicePayments]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO InvoicePaymentsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END