CREATE TABLE [dbo].[ExchangeSalesOrderStockLine] (
    [SOStockLineId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderId]     BIGINT          NOT NULL,
    [ExchangeSalesOrderPartId] BIGINT          NOT NULL,
    [StockLIneId]              BIGINT          NOT NULL,
    [ItemMasterId]             BIGINT          NOT NULL,
    [ConditionId]              BIGINT          NOT NULL,
    [Quantity]                 DECIMAL (18, 6) NULL,
    [QtyReserved]              DECIMAL (18, 6) NULL,
    [QtyIssued]                DECIMAL (18, 6) NULL,
    [AltPartMasterPartId]      BIGINT          NULL,
    [EquPartMasterPartId]      BIGINT          NULL,
    [IsAltPart]                BIT             NULL,
    [IsEquPart]                BIT             NULL,
    [UnitCost]                 DECIMAL (18, 6) NULL,
    [ExtendedCost]             DECIMAL (18, 6) NULL,
    [UnitPrice]                DECIMAL (18, 6) NULL,
    [ExtendedPrice]            DECIMAL (18, 6) NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderStockLine_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrderStockLine_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_ExchangeSalesOrderStockLine_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_ExchangeSalesOrderStockLine_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ReferenceNumber]          VARCHAR (100)   NULL,
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