CREATE TABLE [dbo].[ExchangeSalesOrderBillingInvoicing] (
    [SOBillingInvoicingId]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]                BIGINT          NOT NULL,
    [InvoiceTypeId]                       BIGINT          NOT NULL,
    [InvoiceNo]                           VARCHAR (256)   NOT NULL,
    [CustomerId]                          BIGINT          NOT NULL,
    [InvoiceDate]                         DATETIME2 (7)   NULL,
    [PrintDate]                           DATETIME2 (7)   NULL,
    [ShipDate]                            DATETIME2 (7)   NULL,
    [EmployeeId]                          BIGINT          NOT NULL,
    [RevType]                             VARCHAR (50)    NULL,
    [SoldToCustomerId]                    BIGINT          NOT NULL,
    [SoldToSiteId]                        BIGINT          NOT NULL,
    [BillToCustomerId]                    BIGINT          NOT NULL,
    [BillToSiteId]                        BIGINT          NOT NULL,
    [BillToAttention]                     VARCHAR (256)   NULL,
    [ShipToCustomerId]                    BIGINT          NOT NULL,
    [ShipToSiteId]                        BIGINT          NOT NULL,
    [ShipToAttention]                     VARCHAR (256)   NULL,
    [IsPartialInvoice]                    BIT             CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicing_IsPartialInvoice] DEFAULT ((0)) NOT NULL,
    [CurrencyId]                          INT             NULL,
    [AvailableCredit]                     DECIMAL (20, 2) NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NOT NULL,
    [UpdatedBy]                           VARCHAR (256)   NOT NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicing_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicing_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                            BIT             CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicing_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT             CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicing_IsDeleted] DEFAULT ((0)) NOT NULL,
    [InvoiceStatus]                       VARCHAR (50)    NULL,
    [InvoiceFilePath]                     VARCHAR (MAX)   NULL,
    [GrandTotal]                          DECIMAL (20, 2) NULL,
    [Level1]                              VARCHAR (200)   NULL,
    [Level2]                              VARCHAR (200)   NULL,
    [Level3]                              VARCHAR (200)   NULL,
    [Level4]                              VARCHAR (200)   NULL,
    [SubTotal]                            DECIMAL (20, 2) NULL,
    [TaxRate]                             DECIMAL (20, 2) NULL,
    [SalesTax]                            DECIMAL (20, 2) NULL,
    [OtherTax]                            DECIMAL (20, 2) NULL,
    [MiscCharges]                         DECIMAL (20, 2) NULL,
    [Freight]                             DECIMAL (20, 2) NULL,
    [PeriodicBillingAmount]               DECIMAL (20, 2) NULL,
    [CogsAmount]                          DECIMAL (20, 2) NULL,
    [BillingAmount]                       DECIMAL (20, 2) NULL,
    [ExchangeSalesOrderScheduleBillingId] BIGINT          NULL,
    [cogs]                                INT             NULL,
    [PostedDate]                          DATETIME2 (7)   NULL,
    [BillingId]                           BIGINT          DEFAULT ((0)) NOT NULL,
    [CreditMemoUsed]                      DECIMAL (18, 2) NULL,
    [RemainingAmount]                     DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderBillingInvoicing] PRIMARY KEY CLUSTERED ([SOBillingInvoicingId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_BillToCustomer] FOREIGN KEY ([BillToCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_InvoiceType] FOREIGN KEY ([InvoiceTypeId]) REFERENCES [dbo].[InvoiceType] ([InvoiceTypeId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_ShipToCustomer] FOREIGN KEY ([ShipToCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicing_SoldToCustomer] FOREIGN KEY ([SoldToCustomerId]) REFERENCES [dbo].[Customer] ([CustomerId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderBillingInvoicingAudit]

   ON  [dbo].[ExchangeSalesOrderBillingInvoicing]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeSalesOrderBillingInvoicingAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END