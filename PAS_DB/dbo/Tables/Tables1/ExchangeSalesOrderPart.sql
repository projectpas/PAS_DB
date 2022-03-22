﻿CREATE TABLE [dbo].[ExchangeSalesOrderPart] (
    [ExchangeSalesOrderPartId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]     BIGINT         NOT NULL,
    [ExchangeQuotePartId]      BIGINT         NULL,
    [ExchangeQuoteId]          BIGINT         NULL,
    [ItemMasterId]             BIGINT         NULL,
    [StockLineId]              BIGINT         NULL,
    [ExchangeCurrencyId]       BIGINT         NULL,
    [LoanCurrencyId]           BIGINT         NULL,
    [ExchangeListPrice]        NUMERIC (9, 2) NULL,
    [EntryDate]                DATETIME2 (7)  NULL,
    [ExchangeOverhaulPrice]    NUMERIC (9, 2) NULL,
    [ExchangeCorePrice]        NUMERIC (9, 2) NULL,
    [EstOfFeeBilling]          INT            NULL,
    [BillingStartDate]         DATETIME2 (7)  NULL,
    [ExchangeOutrightPrice]    NUMERIC (9, 2) NULL,
    [DaysForCoreReturn]        INT            NULL,
    [BillingIntervalDays]      INT            NULL,
    [CurrencyId]               INT            NULL,
    [Currency]                 VARCHAR (50)   NULL,
    [DepositeAmount]           NUMERIC (9, 2) NULL,
    [CoreDueDate]              DATETIME2 (7)  NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ExchangeSalesOrderPart_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  CONSTRAINT [DF_ExchangeSalesOrderPart_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]                BIT            CONSTRAINT [DF_ExchangeSalesOrderPart_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]                 BIT            CONSTRAINT [DF_ExchangeSalesOrderPart_IsActive] DEFAULT ((1)) NOT NULL,
    [ConditionId]              BIGINT         NULL,
    [StockLineName]            NVARCHAR (100) NULL,
    [PartNumber]               NVARCHAR (100) NULL,
    [PartDescription]          NVARCHAR (MAX) NULL,
    [ConditionName]            NVARCHAR (100) NULL,
    [IsRemark]                 BIT            CONSTRAINT [DF_ExchangeSalesOrderPart_IsRemark] DEFAULT ((0)) NULL,
    [RemarkText]               VARCHAR (MAX)  NULL,
    [ExchangeOverhaulCost]     NUMERIC (9, 2) NULL,
    [QtyQuoted]                INT            NULL,
    [MethodType]               CHAR (1)       NULL,
    [IsConvertedToSalesOrder]  BIT            CONSTRAINT [DF_ExchangeSalesOrderPart_IsConvertedToSalesOrder] DEFAULT ((0)) NOT NULL,
    [CustomerRequestDate]      DATETIME2 (7)  NULL,
    [PromisedDate]             DATETIME2 (7)  NULL,
    [EstimatedShipDate]        DATETIME2 (7)  NULL,
    [ExpectedCoreSN]           VARCHAR (50)   NULL,
    [StatusId]                 INT            NULL,
    [StatusName]               NVARCHAR (50)  NULL,
    [FxRate]                   NUMERIC (9, 4) NULL,
    [UnitCost]                 NUMERIC (9, 2) NULL,
    [PriorityId]               BIGINT         NULL,
    [Qty]                      INT            NULL,
    [QtyRequested]             INT            NULL,
    [ControlNumber]            VARCHAR (50)   NULL,
    [IdNumber]                 VARCHAR (100)  NULL,
    [Notes]                    NVARCHAR (MAX) NULL,
    [ExpecedCoreCond]          BIGINT         NULL,
    [ExpectedCoreRetDate]      DATETIME2 (7)  NULL,
    [CoreRetDate]              DATETIME2 (7)  NULL,
    [CoreRetNum]               NVARCHAR (100) NULL,
    [CoreStatusId]             INT            DEFAULT ((1)) NOT NULL,
    [LetterSentDate]           DATETIME2 (7)  NULL,
    [LetterTypeId]             INT            NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [ExpdCoreSN]               VARCHAR (100)  NULL,
    [POId]                     BIGINT         NULL,
    [PONumber]                 VARCHAR (100)  NULL,
    [PONextDlvrDate]           DATETIME       NULL,
    CONSTRAINT [PK_ExchangeSalesOrderPart] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderPartId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderPart_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_ExchangeSalesOrderPart_ExchangeQuote] FOREIGN KEY ([ExchangeQuoteId]) REFERENCES [dbo].[ExchangeQuote] ([ExchangeQuoteId]),
    CONSTRAINT [FK_ExchangeSalesOrderPart_ExchangeQuotePart] FOREIGN KEY ([ExchangeQuotePartId]) REFERENCES [dbo].[ExchangeQuotePart] ([ExchangeQuotePartId]),
    CONSTRAINT [FK_ExchangeSalesOrderPart_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ExchangeSalesOrderPart_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrderPart_Stockline] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderPartAudit]

   ON  [dbo].[ExchangeSalesOrderPart]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderPartAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END