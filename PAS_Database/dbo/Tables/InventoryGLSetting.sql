CREATE TABLE [dbo].[InventoryGLSetting] (
    [InventoryGLSettingId]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [StockInventoryName]                VARCHAR (150)  NULL,
    [InventoryGLAccId]                  BIGINT         NULL,
    [InventoryGLAccCode]                NVARCHAR (250) NULL,
    [GoodsReceivedNotInvoicesGLAccId]   BIGINT         NULL,
    [GoodsReceivedNotInvoicesGLAccCode] NVARCHAR (250) NULL,
    [WorkInProgressGLAccId]             BIGINT         NULL,
    [WorkInProgressGLAccCode]           NVARCHAR (250) NULL,
    [InventoryToBillGLAccId]            BIGINT         NULL,
    [InventoryToBillGLAccCode]          NVARCHAR (250) NULL,
    [FinishedGoodsGLAccId]              BIGINT         NULL,
    [FinishedGoodsGLAccCode]            NVARCHAR (250) NULL,
    [InventoryExchAgreementGLAccId]     BIGINT         NULL,
    [InventoryExchAgreementGLAccCode]   NVARCHAR (250) NULL,
    [InventoryReserveGLAccId]           BIGINT         NULL,
    [InventoryReserveGLAccCode]         NVARCHAR (250) NULL,
    [COGS_WorkOrderGLAccId]             BIGINT         NULL,
    [COGS_WorkOrderGLAccCode]           NVARCHAR (250) NULL,
    [COGS_SalesOrderGLAccId]            BIGINT         NULL,
    [COGS_SalesOrderGLAccCode]          NVARCHAR (250) NULL,
    [COGS_ExchSalesOrderGLAccId]        BIGINT         NULL,
    [COGS_ExchSalesOrderGLAccCode]      NVARCHAR (250) NULL,
    [COGS_QtyVarianceGLAccId]           BIGINT         NULL,
    [COGS_QtyVarianceGLAccCode]         NVARCHAR (250) NULL,
    [COGS_UnitCostVarianceGLAccId]      BIGINT         NULL,
    [COGS_UnitCostVarianceGLAccCode]    NVARCHAR (250) NULL,
    [RevenueMroGLAccId]                 BIGINT         NULL,
    [RevenueMroGLAccCode]               NVARCHAR (250) NULL,
    [RevenueSoGLAccId]                  BIGINT         NULL,
    [RevenueSoGLAccCode]                NVARCHAR (250) NULL,
    [RevenueExchGLAccId]                BIGINT         NULL,
    [RevenueExchGLAccCode]              NVARCHAR (250) NULL,
    [MasterCompanyId]                   INT            NOT NULL,
    [CreatedBy]                         VARCHAR (256)  NOT NULL,
    [UpdatedBy]                         VARCHAR (256)  NOT NULL,
    [CreatedDate]                       DATETIME       NOT NULL,
    [UpdatedDate]                       DATETIME       NOT NULL,
    [Memo]                              VARCHAR (MAX)  NULL,
    [IsActive]                          BIT            CONSTRAINT [DF__tmp_ms_xx__IsAct__5BF257F4] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                         BIT            CONSTRAINT [DF__tmp_ms_xx__IsDel__5CE67C2D] DEFAULT ((0)) NOT NULL,
    [IsStock]                           BIT            CONSTRAINT [DF_InventoryGLSetting_IsStock] DEFAULT ((1)) NOT NULL
);












GO

CREATE   TRIGGER [dbo].[Trg_InventoryGLSetting_Audit]
ON [dbo].[InventoryGLSetting]
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    -- Handle INSERT operations
    IF EXISTS (SELECT 1 FROM inserted) 
    BEGIN
        INSERT INTO [dbo].[InventoryGLSettingAudit]
        (
            InventoryGLSettingId,
            IsStock,
            StockInventoryName,
            InventoryGLAccId,
            GoodsReceivedNotInvoicesGLAccId,
            WorkInProgressGLAccId,
            InventoryToBillGLAccId,
            FinishedGoodsGLAccId,
            InventoryExchAgreementGLAccId,
            InventoryReserveGLAccId,
            COGS_WorkOrderGLAccId,
            COGS_SalesOrderGLAccId,
            COGS_ExchSalesOrderGLAccId,
            COGS_QtyVarianceGLAccId,
            COGS_UnitCostVarianceGLAccId,
            RevenueMroGLAccId,
            RevenueSoGLAccId,
            RevenueExchGLAccId,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate,
            Memo,
            IsActive,
            IsDeleted
        )
        SELECT
            InventoryGLSettingId,
            IsStock,
            StockInventoryName,
            InventoryGLAccId,
            GoodsReceivedNotInvoicesGLAccId,
            WorkInProgressGLAccId,
            InventoryToBillGLAccId,
            FinishedGoodsGLAccId,
            InventoryExchAgreementGLAccId,
            InventoryReserveGLAccId,
            COGS_WorkOrderGLAccId,
            COGS_SalesOrderGLAccId,
            COGS_ExchSalesOrderGLAccId,
            COGS_QtyVarianceGLAccId,
            COGS_UnitCostVarianceGLAccId,
            RevenueMroGLAccId,
            RevenueSoGLAccId,
            RevenueExchGLAccId,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            GETUTCDATE(),
            Memo,
            IsActive,
            IsDeleted
        FROM inserted;
    END

END