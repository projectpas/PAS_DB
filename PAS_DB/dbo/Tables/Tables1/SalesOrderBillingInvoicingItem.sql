CREATE TABLE [dbo].[SalesOrderBillingInvoicingItem] (
    [SOBillingInvoicingItemId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SOBillingInvoicingId]     BIGINT          NOT NULL,
    [NoofPieces]               INT             NOT NULL,
    [SalesOrderPartId]         BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderBillingInvoicingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderBillingInvoicingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [SalesOrderBillingInvoicingItem_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [SalesOrderBillingInvoicingItem_DC_Deleted] DEFAULT ((0)) NOT NULL,
    [UnitPrice]                DECIMAL (20, 2) NULL,
    [SalesOrderShippingId]     BIGINT          NULL,
    [PDFPath]                  NVARCHAR (MAX)  NULL,
    [StockLineId]              BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderBillingInvoicingItem] PRIMARY KEY CLUSTERED ([SOBillingInvoicingItemId] ASC),
    CONSTRAINT [FK_SalesOrderBillingInvoicingItem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderBillingInvoicingItem_SalesOrderBillingInvoicing] FOREIGN KEY ([SOBillingInvoicingId]) REFERENCES [dbo].[SalesOrderBillingInvoicing] ([SOBillingInvoicingId])
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderBillingInvoicingItemAudit]

   ON  [dbo].[SalesOrderBillingInvoicingItem]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderBillingInvoicingItemAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END