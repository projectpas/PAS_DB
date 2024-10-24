﻿CREATE TABLE [dbo].[SalesOrderQuotePartV1Audit] (
    [AuditSalesOrderQuotePartId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuotePartId]      BIGINT          NOT NULL,
    [SalesOrderQuoteId]          BIGINT          NOT NULL,
    [ItemMasterId]               BIGINT          NOT NULL,
    [ConditionId]                BIGINT          NOT NULL,
    [QtyRequested]               INT             NOT NULL,
    [QtyQuoted]                  INT             NOT NULL,
    [CurrencyId]                 INT             NULL,
    [PriorityId]                 BIGINT          NOT NULL,
    [StatusId]                   INT             NOT NULL,
    [FxRate]                     DECIMAL (18, 4) NULL,
    [CustomerRequestDate]        DATETIME2 (7)   NULL,
    [PromisedDate]               DATETIME2 (7)   NULL,
    [EstimatedShipDate]          DATETIME2 (7)   NULL,
    [IsConvertedToSalesOrder]    BIT             NULL,
    [IsNoQuote]                  BIT             NULL,
    [IsLotAssigned]              BIT             NULL,
    [LotId]                      BIGINT          NULL,
    [Notes]                      NVARCHAR (MAX)  NULL,
    [SalesPriceExpiryDate]       DATETIME2 (7)   NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   NOT NULL,
    [IsActive]                   BIT             NOT NULL,
    [IsDeleted]                  BIT             NOT NULL,
    [PartNumber]                 VARCHAR (100)   NULL,
    [PartDescription]            NVARCHAR (MAX)  NULL,
    [ConditionName]              VARCHAR (100)   NULL,
    [CurrencyName]               VARCHAR (100)   NULL,
    [PriorityName]               VARCHAR (100)   NULL,
    [StatusName]                 VARCHAR (100)   NULL,
    [OldSalesOrderQuotePartId]   BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderQuotePartV1Audit] PRIMARY KEY CLUSTERED ([AuditSalesOrderQuotePartId] ASC)
);



