﻿CREATE TABLE [dbo].[SalesOrderQuoteStocklineV1Audit] (
    [AuditSalesOrderQuoteStocklineId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteStocklineId]      BIGINT        NOT NULL,
    [SalesOrderQuotePartId]           BIGINT        NOT NULL,
    [StockLineId]                     BIGINT        NOT NULL,
    [ConditionId]                     BIGINT        NOT NULL,
    [QtyQuoted]                       INT           NOT NULL,
    [QtyAvailable]                    INT           NOT NULL,
    [QtyOH]                           INT           NOT NULL,
    [CustomerRequestDate]             DATETIME2 (7) NULL,
    [PromisedDate]                    DATETIME2 (7) NULL,
    [EstimatedShipDate]               DATETIME2 (7) NULL,
    [StatusId]                        INT           NOT NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) NOT NULL,
    [IsActive]                        BIT           NOT NULL,
    [IsDeleted]                       BIT           NOT NULL,
    [StocklineNumber]                 VARCHAR (100) NULL,
    [Condition]                       VARCHAR (100) NULL,
    [StatusName]                      VARCHAR (100) NULL,
    CONSTRAINT [PK_SalesOrderQuoteStocklineV1Audit] PRIMARY KEY CLUSTERED ([AuditSalesOrderQuoteStocklineId] ASC)
);

