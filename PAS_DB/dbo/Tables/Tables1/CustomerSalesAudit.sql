CREATE TABLE [dbo].[CustomerSalesAudit] (
    [CustomerSalesAuditId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [CustomerSalesId]        BIGINT          NOT NULL,
    [CustomerId]             BIGINT          NOT NULL,
    [PrimarySalesPersonId]   BIGINT          NOT NULL,
    [SecondarySalesPersonId] BIGINT          NULL,
    [CsrId]                  BIGINT          NULL,
    [SaId]                   BIGINT          NULL,
    [AnnualRevenuePotential] DECIMAL (16, 2) NOT NULL,
    [AnnualQuota]            DECIMAL (16, 2) NOT NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   NOT NULL,
    [IsActive]               BIT             NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    CONSTRAINT [PK_CustomerSalesAudit] PRIMARY KEY CLUSTERED ([CustomerSalesAuditId] ASC),
    CONSTRAINT [FK_CustomerSalesAudit_CustomerSales] FOREIGN KEY ([CustomerSalesId]) REFERENCES [dbo].[CustomerSales] ([CustomerSalesId])
);

