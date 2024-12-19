CREATE TABLE [dbo].[InventoryGLSettingAudit] (
    [InventoryGLSettingAuditId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [InventoryGLSettingId]            BIGINT        NOT NULL,
    [StockInventoryName]              VARCHAR (150) NOT NULL,
    [InventoryGLAccId]                BIGINT        NOT NULL,
    [GoodsReceivedNotInvoicesGLAccId] BIGINT        NOT NULL,
    [WorkInProgressGLAccId]           BIGINT        NOT NULL,
    [InventoryToBillGLAccId]          BIGINT        NOT NULL,
    [FinishedGoodsGLAccId]            BIGINT        NOT NULL,
    [InventoryExchAgreementGLAccId]   BIGINT        NOT NULL,
    [InventoryReserveGLAccId]         BIGINT        NOT NULL,
    [COGS_WorkOrderGLAccId]           BIGINT        NOT NULL,
    [COGS_SalesOrderGLAccId]          BIGINT        NOT NULL,
    [COGS_QtyVarianceGLAccId]         BIGINT        NOT NULL,
    [COGS_UnitCostVarianceGLAccId]    BIGINT        NOT NULL,
    [RevenueMroGLAccId]               BIGINT        NOT NULL,
    [RevenueSoGLAccId]                BIGINT        NOT NULL,
    [RevenueMiscGLAccId]              BIGINT        NOT NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME      NOT NULL,
    [UpdatedDate]                     DATETIME      NOT NULL,
    [Memo]                            VARCHAR (MAX) NULL,
    [IsActive]                        BIT           NOT NULL,
    [IsDeleted]                       BIT           NOT NULL
);



