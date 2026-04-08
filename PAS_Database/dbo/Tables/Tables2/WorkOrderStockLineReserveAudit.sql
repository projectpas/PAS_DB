CREATE TABLE [dbo].[WorkOrderStockLineReserveAudit] (
    [WOSReserveAuditId]    BIGINT          IDENTITY (1, 1) NOT NULL,
    [WOSReserveId]         BIGINT          NOT NULL,
    [WorkOrderMaterialsId] BIGINT          NOT NULL,
    [StockLineId]          BIGINT          NOT NULL,
    [QtyReserved]          DECIMAL (18, 6) NULL,
    [IsReserved]           BIT             NOT NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME2 (7)   NOT NULL,
    [UpdatedDate]          DATETIME2 (7)   NOT NULL,
    [IsActive]             BIT             NOT NULL,
    [IsDeleted]            BIT             NOT NULL,
    [ConditionId]          BIGINT          NULL,
    CONSTRAINT [PK_WorkOrderStockLineReserveAudit] PRIMARY KEY CLUSTERED ([WOSReserveAuditId] ASC)
);

