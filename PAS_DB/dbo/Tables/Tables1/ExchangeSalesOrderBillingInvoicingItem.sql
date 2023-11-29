CREATE TABLE [dbo].[ExchangeSalesOrderBillingInvoicingItem] (
    [ExchangeSOBillingInvoicingItemId]    BIGINT          IDENTITY (1, 1) NOT NULL,
    [SOBillingInvoicingId]                BIGINT          NOT NULL,
    [NoofPieces]                          INT             NOT NULL,
    [ExchangeSalesOrderPartId]            BIGINT          NOT NULL,
    [ItemMasterId]                        BIGINT          NOT NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NOT NULL,
    [UpdatedBy]                           VARCHAR (256)   NOT NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicingItem_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicingItem_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                            BIT             CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicingItem_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT             CONSTRAINT [DF_ExchangeSalesOrderBillingInvoicingItem_IsDeleted] DEFAULT ((0)) NOT NULL,
    [UnitPrice]                           DECIMAL (20, 2) NULL,
    [ExchangeSalesOrderShippingId]        BIGINT          NULL,
    [ExchangeSalesOrderScheduleBillingId] BIGINT          NULL,
    CONSTRAINT [PK_ExchangeSalesOrderBillingInvoicingItem] PRIMARY KEY CLUSTERED ([ExchangeSOBillingInvoicingItemId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicingItem_ExchangeSalesOrderBillingInvoicing] FOREIGN KEY ([SOBillingInvoicingId]) REFERENCES [dbo].[ExchangeSalesOrderBillingInvoicing] ([SOBillingInvoicingId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicingItem_ExchangeSalesOrderPart] FOREIGN KEY ([ExchangeSalesOrderPartId]) REFERENCES [dbo].[ExchangeSalesOrderPart] ([ExchangeSalesOrderPartId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicingItem_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ExchangeSalesOrderBillingInvoicingItem_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderBillingInvoicingItemAudit]

   ON  [dbo].[ExchangeSalesOrderBillingInvoicingItem]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderBillingInvoicingItemAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END