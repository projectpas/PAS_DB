﻿CREATE TABLE [dbo].[SalesOrderQuotePartV1] (
    [SalesOrderQuotePartId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]       BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [ConditionId]             BIGINT          NOT NULL,
    [QtyRequested]            INT             NOT NULL,
    [QtyQuoted]               INT             NOT NULL,
    [CurrencyId]              INT             NULL,
    [PriorityId]              BIGINT          NOT NULL,
    [StatusId]                INT             NOT NULL,
    [FxRate]                  DECIMAL (18, 4) NULL,
    [CustomerRequestDate]     DATETIME2 (7)   NULL,
    [PromisedDate]            DATETIME2 (7)   NULL,
    [EstimatedShipDate]       DATETIME2 (7)   NULL,
    [IsConvertedToSalesOrder] BIT             DEFAULT ((0)) NULL,
    [IsNoQuote]               BIT             NULL,
    [IsLotAssigned]           BIT             NULL,
    [LotId]                   BIGINT          NULL,
    [Notes]                   NVARCHAR (MAX)  NULL,
    [SalesPriceExpiryDate]    DATETIME2 (7)   NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuotePartV1_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuotePartV1_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_SalesOrderQuotePartV1_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_SalesOrderQuotePartV1_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PartNumber]              VARCHAR (100)   NULL,
    [PartDescription]         NVARCHAR (MAX)  NULL,
    [ConditionName]           VARCHAR (100)   NULL,
    [CurrencyName]            VARCHAR (100)   NULL,
    [PriorityName]            VARCHAR (100)   NULL,
    [StatusName]              VARCHAR (100)   NULL,
    [OldSalesOrderPartId]     BIGINT          NULL,
    CONSTRAINT [PK_SalesOrderQuotePartV1] PRIMARY KEY CLUSTERED ([SalesOrderQuotePartId] ASC),
    CONSTRAINT [FK_SalesOrderQuotePartV1_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuotePartV1_Priority] FOREIGN KEY ([PriorityId]) REFERENCES [dbo].[Priority] ([PriorityId])
);






GO
CREATE TRIGGER [dbo].[Trg_SalesOrderQuotePartV1Audit]
   ON  [dbo].[SalesOrderQuotePartV1]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO SalesOrderQuotePartV1Audit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END