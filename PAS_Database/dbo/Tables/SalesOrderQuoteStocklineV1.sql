CREATE TABLE [dbo].[SalesOrderQuoteStocklineV1] (
    [SalesOrderQuoteStocklineId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuotePartId]      BIGINT        NOT NULL,
    [StockLineId]                BIGINT        NOT NULL,
    [ConditionId]                BIGINT        NOT NULL,
    [QtyQuoted]                  INT           NOT NULL,
    [QtyAvailable]               INT           NOT NULL,
    [QtyOH]                      INT           NOT NULL,
    [CustomerRequestDate]        DATETIME2 (7) NULL,
    [PromisedDate]               DATETIME2 (7) NULL,
    [EstimatedShipDate]          DATETIME2 (7) NULL,
    [StatusId]                   INT           NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteStocklineV1_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_SalesOrderQuoteStocklineV1_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [DF_SalesOrderQuoteStocklineV1_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [DF_SalesOrderQuoteStocklineV1_IsDeleted] DEFAULT ((0)) NOT NULL,
    [StocklineNumber]            VARCHAR (100) NULL,
    [Condition]                  VARCHAR (100) NULL,
    [StatusName]                 VARCHAR (100) NULL,
    CONSTRAINT [PK_SalesOrderQuoteStocklineV1] PRIMARY KEY CLUSTERED ([SalesOrderQuoteStocklineId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteStocklineV1_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
Create TRIGGER [dbo].[Trg_SalesOrderQuoteStocklineV1Audit]
   ON  [dbo].[SalesOrderQuoteStocklineV1]
   AFTER INSERT,DELETE,UPDATE
AS 
BEGIN
	INSERT INTO SalesOrderQuoteStocklineV1Audit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END