CREATE TABLE [dbo].[SalesOrderQuotePart] (
    [SalesOrderQuotePartId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]       BIGINT         NULL,
    [ItemMasterId]            BIGINT         NULL,
    [StockLineId]             BIGINT         NULL,
    [FxRate]                  NUMERIC (9, 4) NULL,
    [QtyQuoted]               INT            NULL,
    [UnitSalePrice]           NUMERIC (9, 2) NULL,
    [MarkUpPercentage]        NUMERIC (9, 2) NULL,
    [SalesBeforeDiscount]     NUMERIC (9, 2) NULL,
    [Discount]                NUMERIC (9, 2) NULL,
    [DiscountAmount]          NUMERIC (9, 2) NULL,
    [NetSales]                NUMERIC (9, 2) NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_SalesOrderQuotePart_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_SalesOrderQuotePart_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]               BIT            DEFAULT ((0)) NOT NULL,
    [UnitCost]                NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MethodType]              CHAR (1)       DEFAULT (NULL) NULL,
    [SalesPriceExtended]      NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarkupExtended]          NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [SalesDiscountExtended]   NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [NetSalePriceExtended]    NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [UnitCostExtended]        NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarginAmount]            NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarginAmountExtended]    NUMERIC (9, 2) DEFAULT ((0)) NOT NULL,
    [MarginPercentage]        NUMERIC (9, 2) NULL,
    [ConditionId]             BIGINT         DEFAULT ((0)) NOT NULL,
    [IsConvertedToSalesOrder] BIT            DEFAULT ((0)) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [SalesOrderQuotePart_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [CustomerRequestDate]     DATETIME2 (7)  NOT NULL,
    [PromisedDate]            DATETIME2 (7)  NULL,
    [EstimatedShipDate]       DATETIME2 (7)  NULL,
    [PriorityId]              BIGINT         NOT NULL,
    [StatusId]                INT            NULL,
    [CustomerReference]       VARCHAR (100)  NULL,
    [QtyRequested]            INT            NULL,
    [Notes]                   NVARCHAR (MAX) NULL,
    [CurrencyId]              INT            NULL,
    [MarkupPerUnit]           NUMERIC (9, 2) NULL,
    [GrossSalePricePerUnit]   NUMERIC (9, 2) NULL,
    [GrossSalePrice]          NUMERIC (9, 2) NULL,
    [TaxType]                 VARCHAR (250)  NULL,
    [TaxPercentage]           NUMERIC (9, 2) NULL,
    [TaxAmount]               NUMERIC (9, 2) NULL,
    [AltOrEqType]             VARCHAR (50)   NULL,
    [QtyPrevQuoted]           INT            NULL,
    [ControlNumber]           VARCHAR (50)   NULL,
    [IdNumber]                VARCHAR (100)  NULL,
    [QtyAvailable]            INT            NULL,
    [StockLineName]           NVARCHAR (100) NULL,
    [PartNumber]              NVARCHAR (100) NULL,
    [PartDescription]         NVARCHAR (MAX) NULL,
    [ConditionName]           NVARCHAR (100) NULL,
    [PriorityName]            NVARCHAR (100) NULL,
    [StatusName]              NVARCHAR (100) NULL,
    [CurrencyName]            NVARCHAR (100) NULL,
    [ItemNo]                  INT            NULL,
    [UnitSalesPricePerUnit]   NUMERIC (9, 2) NULL,
    [IsLotAssigned]           BIT            NULL,
    [LotId]                   BIGINT         NULL,
    [SalesPriceExpiryDate]    DATETIME2 (7)  NULL,
    CONSTRAINT [PK_SalesOrderQuotePart] PRIMARY KEY CLUSTERED ([SalesOrderQuotePartId] ASC),
    CONSTRAINT [FK_SalesOrderQuotePart_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SalesOrderQuotePart_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SalesOrderQuotePart_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SalesOrderQuotePart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuotePart_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId]),
    CONSTRAINT [FK_SalesOrderQuotePart_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderQuotePart_StockLine] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [Unique_SalesOrderQuotePart] UNIQUE NONCLUSTERED ([SalesOrderQuoteId] ASC, [ItemMasterId] ASC, [StockLineId] ASC, [MasterCompanyId] ASC, [ConditionId] ASC)
);






GO


CREATE TRIGGER [dbo].[Trg_SalesOrderQuotePartAudit]

   ON  [dbo].[SalesOrderQuotePart]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderQuotePartAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END