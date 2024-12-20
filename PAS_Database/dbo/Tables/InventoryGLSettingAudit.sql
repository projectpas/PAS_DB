CREATE TABLE [dbo].[InventoryGLSettingAudit] (
    [InventoryGLSettingAuditId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [InventoryGLSettingId]            BIGINT        NULL,
    [StockInventoryName]              VARCHAR (150) NULL,
    [InventoryGLAccId]                BIGINT        NULL,
    [GoodsReceivedNotInvoicesGLAccId] BIGINT        NULL,
    [WorkInProgressGLAccId]           BIGINT        NULL,
    [InventoryToBillGLAccId]          BIGINT        NULL,
    [FinishedGoodsGLAccId]            BIGINT        NULL,
    [InventoryExchAgreementGLAccId]   BIGINT        NULL,
    [InventoryReserveGLAccId]         BIGINT        NULL,
    [COGS_WorkOrderGLAccId]           BIGINT        NULL,
    [COGS_SalesOrderGLAccId]          BIGINT        NULL,
    [COGS_QtyVarianceGLAccId]         BIGINT        NULL,
    [COGS_UnitCostVarianceGLAccId]    BIGINT        NULL,
    [RevenueMroGLAccId]               BIGINT        NULL,
    [RevenueSoGLAccId]                BIGINT        NULL,
    [RevenueMiscGLAccId]              BIGINT        NULL,
    [MasterCompanyId]                 INT           NULL,
    [CreatedBy]                       VARCHAR (256) NULL,
    [UpdatedBy]                       VARCHAR (256) NULL,
    [CreatedDate]                     DATETIME      NULL,
    [UpdatedDate]                     DATETIME      NULL,
    [Memo]                            VARCHAR (MAX) NULL,
    [IsActive]                        BIT           NULL,
    [IsDeleted]                       BIT           NULL
);





