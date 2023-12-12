CREATE TABLE [dbo].[SalesOrderBillingInvoicing] (
    [SOBillingInvoicingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]         BIGINT          NOT NULL,
    [InvoiceTypeId]        BIGINT          NOT NULL,
    [InvoiceNo]            VARCHAR (256)   NOT NULL,
    [CustomerId]           BIGINT          NOT NULL,
    [InvoiceDate]          DATETIME2 (7)   NULL,
    [PrintDate]            DATETIME2 (7)   NULL,
    [ShipDate]             DATETIME2 (7)   NULL,
    [EmployeeId]           BIGINT          NOT NULL,
    [RevType]              VARCHAR (50)    NULL,
    [SoldToCustomerId]     BIGINT          NOT NULL,
    [SoldToSiteId]         BIGINT          NOT NULL,
    [BillToCustomerId]     BIGINT          NOT NULL,
    [BillToSiteId]         BIGINT          NOT NULL,
    [BillToAttention]      VARCHAR (256)   NULL,
    [ShipToCustomerId]     BIGINT          NOT NULL,
    [ShipToSiteId]         BIGINT          NOT NULL,
    [ShipToAttention]      VARCHAR (256)   NULL,
    [IsPartialInvoice]     BIT             CONSTRAINT [SalesOrderBillingInvoicing_DC_IsPartialInvoice] DEFAULT ((0)) NOT NULL,
    [CurrencyId]           INT             NULL,
    [AvailableCredit]      DECIMAL (20, 2) NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   CONSTRAINT [DF_SalesOrderBillingInvoicing_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   CONSTRAINT [DF_SalesOrderBillingInvoicing_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT             CONSTRAINT [SalesOrderBillingInvoicing_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [SalesOrderBillingInvoicing_DC_Deleted] DEFAULT ((0)) NOT NULL,
    [InvoiceStatus]        VARCHAR (50)    NULL,
    [InvoiceFilePath]      VARCHAR (200)   NULL,
    [GrandTotal]           DECIMAL (20, 2) NULL,
    [Level1]               VARCHAR (200)   NULL,
    [Level2]               VARCHAR (200)   NULL,
    [Level3]               VARCHAR (200)   NULL,
    [Level4]               VARCHAR (200)   NULL,
    [SubTotal]             DECIMAL (20, 2) NULL,
    [TaxRate]              DECIMAL (20, 2) NULL,
    [SalesTax]             DECIMAL (20, 2) NULL,
    [OtherTax]             DECIMAL (20, 2) NULL,
    [MiscCharges]          DECIMAL (20, 2) NULL,
    [Freight]              DECIMAL (20, 2) NULL,
    [RemainingAmount]      DECIMAL (20, 2) NULL,
    [PostedDate]           DATETIME2 (7)   NULL,
    [Notes]                NVARCHAR (MAX)  NULL,
    [SalesTotal]           DECIMAL (20, 2) NULL,
    [CreditMemoUsed]       DECIMAL (18, 2) NULL,
    [VersionNo]            VARCHAR (100)   NULL,
    [IsVersionIncrease]    BIT             NULL,
    CONSTRAINT [PK_SalesOrderBillingInvoicing] PRIMARY KEY CLUSTERED ([SOBillingInvoicingId] ASC),
    CONSTRAINT [FK_SalesOrderBillingInvoicing_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderBillingInvoicing_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId])
);


GO


CREATE TRIGGER [dbo].[Trg_SalesOrderBillingInvoicingAudit]

   ON  [dbo].[SalesOrderBillingInvoicing]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderBillingInvoicingAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END