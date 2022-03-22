CREATE TABLE [dbo].[SalesOrderStockLine] (
    [SOStockLineId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]        BIGINT          NOT NULL,
    [SalesOrderPartId]    BIGINT          NOT NULL,
    [StockLIneId]         BIGINT          NOT NULL,
    [ItemMasterId]        BIGINT          NOT NULL,
    [ConditionId]         BIGINT          NOT NULL,
    [Quantity]            INT             NULL,
    [QtyReserved]         INT             NULL,
    [QtyIssued]           INT             NULL,
    [AltPartMasterPartId] BIGINT          NULL,
    [EquPartMasterPartId] BIGINT          NULL,
    [IsAltPart]           BIT             NULL,
    [IsEquPart]           BIT             NULL,
    [UnitCost]            DECIMAL (20, 2) NULL,
    [ExtendedCost]        DECIMAL (20, 2) NULL,
    [UnitPrice]           DECIMAL (20, 2) NULL,
    [ExtendedPrice]       DECIMAL (20, 2) NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   CONSTRAINT [DF_SalesOrderStockLine_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   CONSTRAINT [DF_SalesOrderStockLine_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT             CONSTRAINT [DF_SalesOrderStockLine_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT             CONSTRAINT [DF_SalesOrderStockLine_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_SalesOrderStockLine] PRIMARY KEY CLUSTERED ([SOStockLineId] ASC),
    CONSTRAINT [FK_SalesOrderStockLine_Condition] FOREIGN KEY ([ConditionId]) REFERENCES [dbo].[Condition] ([ConditionId]),
    CONSTRAINT [FK_SalesOrderStockLine_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_SalesOrderStockLine_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderStockLine_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderStockLine_SalesOrderPart] FOREIGN KEY ([SalesOrderPartId]) REFERENCES [dbo].[SalesOrderPart] ([SalesOrderPartId]),
    CONSTRAINT [FK_SalesOrderStockLine_StockLine] FOREIGN KEY ([StockLIneId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);


GO




CREATE TRIGGER [dbo].[Trg_SalesOrderStockLineAudit]

   ON  [dbo].[SalesOrderStockLine]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO SalesOrderStockLineAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END