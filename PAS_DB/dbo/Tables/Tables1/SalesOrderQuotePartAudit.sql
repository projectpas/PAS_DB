﻿CREATE TABLE [dbo].[SalesOrderQuotePartAudit] (
    [AuditSalesOrderQuotePartId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuotePartId]      BIGINT         NOT NULL,
    [SalesOrderQuoteId]          BIGINT         NULL,
    [ItemMasterId]               BIGINT         NULL,
    [StockLineId]                BIGINT         NULL,
    [FxRate]                     NUMERIC (9, 4) NULL,
    [QtyQuoted]                  INT            NULL,
    [UnitSalePrice]              NUMERIC (9, 2) NULL,
    [MarkUpPercentage]           INT            NULL,
    [SalesBeforeDiscount]        NUMERIC (9, 2) NULL,
    [Discount]                   INT            NULL,
    [DiscountAmount]             NUMERIC (9, 2) NULL,
    [NetSales]                   NUMERIC (9, 2) NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  NOT NULL,
    [IsDeleted]                  BIT            NOT NULL,
    [UnitCost]                   NUMERIC (9, 2) NOT NULL,
    [MethodType]                 CHAR (1)       NULL,
    [SalesPriceExtended]         NUMERIC (9, 2) NOT NULL,
    [MarkupExtended]             NUMERIC (9, 2) NOT NULL,
    [SalesDiscountExtended]      NUMERIC (9, 2) NOT NULL,
    [NetSalePriceExtended]       NUMERIC (9, 2) NOT NULL,
    [UnitCostExtended]           NUMERIC (9, 2) NOT NULL,
    [MarginAmount]               NUMERIC (9, 2) NOT NULL,
    [MarginAmountExtended]       NUMERIC (9, 2) NOT NULL,
    [MarginPercentage]           NUMERIC (9, 2) NULL,
    [ConditionId]                BIGINT         NOT NULL,
    [IsConvertedToSalesOrder]    BIT            NOT NULL,
    [IsActive]                   BIT            NOT NULL,
    [CustomerRequestDate]        DATETIME2 (7)  NOT NULL,
    [PromisedDate]               DATETIME2 (7)  NULL,
    [EstimatedShipDate]          DATETIME2 (7)  NULL,
    [PriorityId]                 INT            NOT NULL,
    [StatusId]                   INT            NULL,
    [CustomerReference]          VARCHAR (100)  NULL,
    [QtyRequested]               INT            NULL,
    [Notes]                      NVARCHAR (MAX) NULL,
    [CurrencyId]                 INT            NULL,
    [MarkupPerUnit]              NUMERIC (9, 2) NULL,
    [GrossSalePricePerUnit]      NUMERIC (9, 2) NULL,
    [GrossSalePrice]             NUMERIC (9, 2) NULL,
    [TaxType]                    VARCHAR (250)  NULL,
    [TaxPercentage]              NUMERIC (9, 2) NULL,
    [TaxAmount]                  NUMERIC (9, 2) NULL,
    [AltOrEqType]                VARCHAR (50)   NULL,
    [QtyPrevQuoted]              INT            NULL,
    [ControlNumber]              VARCHAR (50)   NULL,
    [IdNumber]                   VARCHAR (100)  NULL,
    [QtyAvailable]               INT            NULL,
    [StockLineName]              NVARCHAR (100) NULL,
    [PartNumber]                 NVARCHAR (100) NULL,
    [PartDescription]            NVARCHAR (MAX) NULL,
    [ConditionName]              NVARCHAR (100) NULL,
    [PriorityName]               NVARCHAR (100) NULL,
    [StatusName]                 NVARCHAR (100) NULL,
    [CurrencyName]               NVARCHAR (100) NULL,
    [ItemNo]                     INT            NULL,
    [UnitSalesPricePerUnit]      NUMERIC (9, 2) NULL,
    [IsLotAssigned]              BIT            NULL,
    [LotId]                      BIGINT         NULL,
    [SalesPriceExpiryDate]       DATETIME2 (7)  NULL,
    CONSTRAINT [PK_SalesOrderQuotePartAudit] PRIMARY KEY CLUSTERED ([AuditSalesOrderQuotePartId] ASC)
);



