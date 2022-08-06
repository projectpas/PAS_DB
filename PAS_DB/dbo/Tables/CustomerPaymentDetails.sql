CREATE TABLE [dbo].[CustomerPaymentDetails] (
    [CustomerPaymentDetailsId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [ReceiptId]                           BIGINT          NOT NULL,
    [IsMultiplePaymentMethod]             BIT             NOT NULL,
    [IsCheckPayment]                      BIT             NULL,
    [IsWireTransfer]                      BIT             NULL,
    [IsCCDCPayment]                       BIT             NULL,
    [IsTradeReceivable]                   BIT             NULL,
    [TradeReceivableORMiscReceiptGLAccnt] BIGINT          NULL,
    [IsDeposite]                          BIT             NULL,
    [PaymentMode]                         INT             NULL,
    [CustomerId]                          BIGINT          NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NOT NULL,
    [UpdatedBy]                           VARCHAR (256)   NOT NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_CustomerPaymentDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_CustomerPaymentDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                            BIT             CONSTRAINT [DF_CustomerPaymentDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT             CONSTRAINT [DF_CustomerPaymentDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PageIndex]                           INT             NULL,
    [CustomerCode]                        VARCHAR (100)   NULL,
    [PaymentRef]                          VARCHAR (100)   NULL,
    [Amount]                              DECIMAL (18, 2) NULL,
    [AmountRem]                           DECIMAL (18, 2) NULL,
    [Ismiscellaneous]                     BIT             DEFAULT ((0)) NOT NULL,
    [AppliedAmount]                       DECIMAL (20, 2) NULL,
    [InvoiceAmount]                       DECIMAL (20, 2) NULL,
    CONSTRAINT [PK_CustomerPaymentDetails] PRIMARY KEY CLUSTERED ([CustomerPaymentDetailsId] ASC)
);




GO
CREATE TRIGGER [dbo].[Trg_CustomerPaymentDetailsAudit]
   ON  [dbo].[CustomerPaymentDetails]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
INSERT INTO CustomerPaymentDetailsAudit
SELECT * FROM INSERTED
SET NOCOUNT ON;
END