CREATE TABLE [dbo].[ExchangeSalesOrderStockLine] (
    [SOStockLineId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]     BIGINT          NOT NULL,
    [ExchangeSalesOrderPartId] BIGINT          NOT NULL,
    [StockLIneId]              BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [ConditionId]              BIGINT          NOT NULL,
    [Quantity]                 INT             NULL,
    [QtyReserved]              INT             NULL,
    [QtyIssued]                INT             NULL,
    [AltPartMasterPartId]      BIGINT          NULL,
    [EquPartMasterPartId]      BIGINT          NULL,
    [IsAltPart]                BIT             NULL,
    [IsEquPart]                BIT             NULL,
    [UnitCost]                 DECIMAL (20, 2) NULL,
    [ExtendedCost]             DECIMAL (20, 2) NULL,
    [UnitPrice]                DECIMAL (20, 2) NULL,
    [ExtendedPrice]            DECIMAL (20, 2) NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderStockLine_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderStockLine_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_ExchangeSalesOrderStockLine_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_ExchangeSalesOrderStockLine_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeSalesOrderStockLine] PRIMARY KEY CLUSTERED ([SOStockLineId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrderStockLine_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_ExchangeSalesOrderStockLine_ExchangeSalesOrder] FOREIGN KEY ([ExchangeSalesOrderId]) REFERENCES [dbo].[ExchangeSalesOrder] ([ExchangeSalesOrderId]),
    CONSTRAINT [FK_ExchangeSalesOrderStockLine_ExchangeSalesOrderPart] FOREIGN KEY ([ExchangeSalesOrderPartId]) REFERENCES [dbo].[ExchangeSalesOrderPart] ([ExchangeSalesOrderPartId]),
    CONSTRAINT [FK_ExchangeSalesOrderStockLine_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ExchangeSalesOrderStockLine_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrderStockLine_Stockline] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderStockLineAudit]

   ON  [dbo].[ExchangeSalesOrderStockLine]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeSalesOrderStockLineAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END