CREATE TABLE [dbo].[SubWorkOrderStockLineReserveAudit] (
    [SWOSReserveAuditId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [SWOSReserveId]           BIGINT        NOT NULL,
    [SubWorkOrderMaterialsId] BIGINT        NOT NULL,
    [StockLIneId]             BIGINT        NOT NULL,
    [QtyReserved]             INT           NULL,
    [IsReserved]              BIT           NOT NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) NOT NULL,
    [IsActive]                BIT           NOT NULL,
    [IsDeleted]               BIT           NOT NULL,
    [ConditionId]             BIGINT        NULL,
    CONSTRAINT [PK_SubWorkOrderStockLineReserveAudit] PRIMARY KEY CLUSTERED ([SWOSReserveAuditId] ASC)
);

