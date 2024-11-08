CREATE TABLE [dbo].[SalesOrderQuoteCostAudit] (
    [AuditSalesOrderQuoteCostId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteCostId]      BIGINT          NOT NULL,
    [SalesOrderQuoteId]          BIGINT          NOT NULL,
    [SubTotal]                   DECIMAL (18, 4) NULL,
    [SalesTax]                   DECIMAL (18, 4) NULL,
    [OtherTax]                   DECIMAL (18, 4) NULL,
    [MiscCharges]                DECIMAL (18, 4) NULL,
    [Freight]                    DECIMAL (18, 4) NULL,
    [NetTotal]                   DECIMAL (18, 4) NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   NOT NULL,
    [IsActive]                   BIT             NOT NULL,
    [IsDeleted]                  BIT             NOT NULL,
    CONSTRAINT [PK_SalesOrderQuoteCostAudit] PRIMARY KEY CLUSTERED ([AuditSalesOrderQuoteCostId] ASC)
);

