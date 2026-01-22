CREATE TABLE [dbo].[UnitSalePriceHistoryAudit] (
    [UnitSalePriceHistoryAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [StockLineId]                 BIGINT          NOT NULL,
    [StocklineNumber]             VARCHAR (50)    NULL,
    [UnitSalesPrice]              DECIMAL (18, 2) NULL,
    [SalesPriceExpiryDate]        DATETIME        NULL,
    [MasterCompanyId]             INT             NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NULL,
    [CreatedDate]                 DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   NULL,
    [IsActive]                    BIT             NULL,
    [IsDeleted]                   BIT             NULL,
    CONSTRAINT [PK_UnitSalePriceHistoryAudit] PRIMARY KEY CLUSTERED ([UnitSalePriceHistoryAuditId] ASC)
);

