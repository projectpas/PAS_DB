CREATE TABLE [dbo].[ExchangeSalesOrderScheduleBillingAudit] (
    [ExchangeSalesOrderScheduleBillingAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderScheduleBillingId]      BIGINT          NOT NULL,
    [ExchangeSalesOrderPartId]                 BIGINT          NOT NULL,
    [ExchangeSalesOrderId]                     BIGINT          NOT NULL,
    [ScheduleBillingDate]                      DATETIME2 (7)   NULL,
    [PeriodicBillingAmount]                    NUMERIC (9, 2)  NOT NULL,
    [Cogs]                                     INT             NOT NULL,
    [CogsAmount]                               NUMERIC (9, 2)  NULL,
    [Qty]                                      INT             NULL,
    [BillingTypeId]                            INT             NULL,
    [UnitOfMeasureId]                          BIGINT          NULL,
    [Notes]                                    NVARCHAR (MAX)  NULL,
    [Memo]                                     NVARCHAR (MAX)  NULL,
    [Type]                                     NVARCHAR (50)   DEFAULT ('Part') NOT NULL,
    [StatusId]                                 INT             DEFAULT ((1)) NOT NULL,
    [ExchangeSalesOrderChargesId]              BIGINT          NULL,
    [ExchangeSalesOrderFreightId]              BIGINT          NULL,
    [IsPartEntry]                              BIT             DEFAULT ((0)) NOT NULL,
    [BillingAmount]                            DECIMAL (20, 2) NULL,
    [MarkupPercentageId]                       INT             NULL,
    [ExtendedCost]                             DECIMAL (20, 2) NULL,
    CONSTRAINT [PK_ExchangeSalesOrderScheduleBillingAudit] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderScheduleBillingAuditId] ASC)
);





