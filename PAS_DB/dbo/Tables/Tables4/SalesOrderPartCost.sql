CREATE TABLE [dbo].[SalesOrderPartCost] (
    [SalesOrderPartCostId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]           BIGINT          NOT NULL,
    [SalesOrderPartId]       BIGINT          NOT NULL,
    [UnitSalesPrice]         DECIMAL (18, 4) NULL,
    [UnitSalesPriceExtended] DECIMAL (18, 4) NULL,
    [UnitCost]               DECIMAL (18, 4) NULL,
    [UnitCostExtended]       DECIMAL (18, 4) NULL,
    [MarkUpPercentage]       DECIMAL (18, 4) NULL,
    [MarkUpAmount]           DECIMAL (18, 4) NULL,
    [MarginAmount]           DECIMAL (18, 4) NULL,
    [MarginPercentage]       DECIMAL (18, 4) NULL,
    [DiscountPercentage]     DECIMAL (18, 4) NULL,
    [DiscountAmount]         DECIMAL (18, 4) NULL,
    [TaxPercentage]          DECIMAL (18, 4) NULL,
    [TaxAmount]              DECIMAL (18, 4) NULL,
    [NetSaleAmount]          DECIMAL (18, 4) NULL,
    [MiscCharges]            DECIMAL (18, 4) NULL,
    [Freight]                DECIMAL (18, 4) NULL,
    [TotalRevenue]           DECIMAL (18, 4) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SalesOrderPartCost_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SalesOrderPartCost_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [DF_SalesOrderPartCost_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_SalesOrderPartCost_IsDeleted] DEFAULT ((0)) NOT NULL,
    [NetSaleAmountPerUnit]   DECIMAL (18, 4) NULL,
    CONSTRAINT [PK_SalesOrderPartCost] PRIMARY KEY CLUSTERED ([SalesOrderPartCostId] ASC)
);




GO
CREATE TRIGGER [dbo].[Trg_SalesOrderPartCostAudit]
   ON  [dbo].[SalesOrderPartCost]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO SalesOrderPartCostAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END
GO
CREATE NONCLUSTERED INDEX [IX_SalesOrderPartCost_SOId_Perf]
    ON [dbo].[SalesOrderPartCost]([SalesOrderId] ASC, [SalesOrderPartId] ASC)
    INCLUDE([NetSaleAmount], [UnitCost]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);


GO
CREATE NONCLUSTERED INDEX [IX_SalesOrderPartCost_PartId_Perf]
    ON [dbo].[SalesOrderPartCost]([SalesOrderPartId] ASC)
    INCLUDE([NetSaleAmount], [UnitCost]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);

