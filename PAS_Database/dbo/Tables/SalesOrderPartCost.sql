CREATE TABLE [dbo].[SalesOrderPartCost] (
    [SalesOrderPartCostId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]           BIGINT          NOT NULL,
    [SalesOrderPartId]       BIGINT          NOT NULL,
    [UnitSalesPrice]         DECIMAL (18, 6) NULL,
    [UnitSalesPriceExtended] DECIMAL (18, 6) NULL,
    [UnitCost]               DECIMAL (18, 6) NULL,
    [UnitCostExtended]       DECIMAL (18, 6) NULL,
    [MarkUpPercentage]       DECIMAL (18, 6) NULL,
    [MarkUpAmount]           DECIMAL (18, 6) NULL,
    [MarginAmount]           DECIMAL (18, 6) NULL,
    [MarginPercentage]       DECIMAL (18, 6) NULL,
    [DiscountPercentage]     DECIMAL (18, 6) NULL,
    [DiscountAmount]         DECIMAL (18, 6) NULL,
    [TaxPercentage]          DECIMAL (18, 6) NULL,
    [TaxAmount]              DECIMAL (18, 6) NULL,
    [GrossSaleAmount]        DECIMAL (18, 6) NULL,
    [NetSaleAmount]          DECIMAL (18, 6) NULL,
    [MiscCharges]            DECIMAL (18, 6) NULL,
    [Freight]                DECIMAL (18, 6) NULL,
    [TotalRevenue]           DECIMAL (18, 6) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SalesOrderPartCost_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_SalesOrderPartCost_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [DF_SalesOrderPartCost_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_SalesOrderPartCost_IsDeleted] DEFAULT ((0)) NOT NULL,
    [NetSaleAmountPerUnit]   DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_SalesOrderPartCost] PRIMARY KEY CLUSTERED ([SalesOrderPartCostId] ASC),
    CONSTRAINT [FK_SalesOrderPartCost_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderPartCost_SalesOrderPartV1] FOREIGN KEY ([SalesOrderPartId]) REFERENCES [dbo].[SalesOrderPartV1] ([SalesOrderPartId]),
    CONSTRAINT [FK_SalesOrderPartCost_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
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