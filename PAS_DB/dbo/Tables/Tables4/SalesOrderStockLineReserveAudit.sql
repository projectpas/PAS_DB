CREATE TABLE [dbo].[SalesOrderStockLineReserveAudit] (
    [SOSReserveAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SOSReserveId]      BIGINT        NOT NULL,
    [SalesOrderId]      BIGINT        NOT NULL,
    [SalesOrderPartId]  BIGINT        NOT NULL,
    [StockLIneId]       BIGINT        NOT NULL,
    [ConditionId]       BIGINT        NULL,
    [QtyReserved]       INT           NULL,
    [IsReserved]        BIT           NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) NOT NULL,
    [IsActive]          BIT           NOT NULL,
    [IsDeleted]         BIT           NOT NULL,
    CONSTRAINT [PK_SalesOrderStockLineReserveAudit] PRIMARY KEY CLUSTERED ([SOSReserveAuditId] ASC)
);

