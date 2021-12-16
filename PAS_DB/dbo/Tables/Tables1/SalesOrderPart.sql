CREATE TABLE [dbo].[SalesOrderPart] (
    [SalesOrderPartId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]          BIGINT         NOT NULL,
    [ItemMasterId]          BIGINT         NULL,
    [StockLineId]           BIGINT         NULL,
    [FxRate]                NUMERIC (9, 4) NULL,
    [Qty]                   INT            NULL,
    [UnitSalePrice]         NUMERIC (9, 2) NULL,
    [MarkUpPercentage]      INT            NULL,
    [SalesBeforeDiscount]   NUMERIC (9, 2) NULL,
    [Discount]              INT            NULL,
    [DiscountAmount]        NUMERIC (9, 2) NULL,
    [NetSales]              NUMERIC (9, 2) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_SalesOrderPart_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_SalesOrderPart_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]             BIT            DEFAULT ((0)) NOT NULL,
    [UnitCost]              NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MethodType]            CHAR (1)       DEFAULT (NULL) NULL,
    [SalesPriceExtended]    NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarkupExtended]        NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [SalesDiscountExtended] NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [NetSalePriceExtended]  NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [UnitCostExtended]      NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarginAmount]          NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarginAmountExtended]  NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarginPercentage]      NUMERIC (9, 2) NOT NULL,
    [ConditionId]           BIGINT         DEFAULT ((0)) NOT NULL,
    [SalesOrderQuoteId]     BIGINT         NULL,
    [SalesOrderQuotePartId] BIGINT         DEFAULT (NULL) NULL,
    [IsActive]              BIT            CONSTRAINT [SalesOrderPart_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [CustomerRequestDate]   DATETIME2 (7)  NOT NULL,
    [PromisedDate]          DATETIME2 (7)  NOT NULL,
    [EstimatedShipDate]     DATETIME2 (7)  NOT NULL,
    [PriorityId]            BIGINT         NOT NULL,
    [StatusId]              INT            NULL,
    [CustomerReference]     VARCHAR (100)  NULL,
    [QtyRequested]          INT            NULL,
    [Notes]                 NVARCHAR (MAX) NULL,
    [CurrencyId]            INT            NULL,
    [MarkupPerUnit]         NUMERIC (9, 2) NULL,
    [GrossSalePricePerUnit] NUMERIC (9, 2) NULL,
    [GrossSalePrice]        NUMERIC (9, 2) NULL,
    [TaxType]               VARCHAR (250)  NULL,
    [TaxPercentage]         NUMERIC (9, 2) NULL,
    [TaxAmount]             NUMERIC (9, 2) NULL,
    [AltOrEqType]           VARCHAR (50)   NULL,
    [ControlNumber]         VARCHAR (50)   NULL,
    [IdNumber]              VARCHAR (100)  NULL,
    [ItemNo]                INT            NULL,
    [POId]                  BIGINT         NULL,
    [PONumber]              VARCHAR (100)  NULL,
    [PONextDlvrDate]        DATETIME       NULL,
    [UnitSalesPricePerUnit] NUMERIC (9, 2) NULL,
    CONSTRAINT [PK_SalesOrderPart] PRIMARY KEY CLUSTERED ([SalesOrderPartId] ASC),
    CONSTRAINT [FK_SalesOrder_SalesOrderId] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderPart_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SalesOrderPart_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SalesOrderPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderPart_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_SalesOrderPart_SalesOrderQuoteId] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderPart_SalesOrderQuotePartId] FOREIGN KEY ([SalesOrderQuotePartId]) REFERENCES [dbo].[SalesOrderQuotePart] ([SalesOrderQuotePartId]),
    CONSTRAINT [FK_SalesOrderPart_StockLineId] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [Unique_SalesOrderPart] UNIQUE NONCLUSTERED ([SalesOrderId] ASC, [ItemMasterId] ASC, [StockLineId] ASC, [MasterCompanyId] ASC, [ConditionId] ASC)
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderPartAudit]

   ON  [dbo].[SalesOrderPart]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderPartAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END