CREATE TABLE [dbo].[InvoiceWireTransferPaymentAudit] (
    [WireTransferAuditId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [WireTransferId]           BIGINT          NOT NULL,
    [ReceiptId]                BIGINT          NOT NULL,
    [CustomerId]               BIGINT          NOT NULL,
    [WireDate]                 DATETIME        NOT NULL,
    [Amount]                   DECIMAL (20, 2) NOT NULL,
    [CurrencyId]               INT             NOT NULL,
    [BankName]                 INT             NULL,
    [ReferenceNo]              VARCHAR (100)   NULL,
    [IMAD_OMADNo]              VARCHAR (100)   NULL,
    [BankAccount]              VARCHAR (256)   NULL,
    [GLAccountNumber]          BIGINT          NOT NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NOT NULL,
    [IsActive]                 BIT             NOT NULL,
    [IsDeleted]                BIT             NOT NULL,
    [PageIndex]                INT             NULL,
    [Ismiscellaneous]          BIT             NULL,
    [CustomerPaymentDetailsId] BIGINT          NULL,
    CONSTRAINT [PK_InvoiceWireTransferAudit] PRIMARY KEY CLUSTERED ([WireTransferAuditId] ASC)
);





