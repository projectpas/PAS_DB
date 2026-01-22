CREATE TABLE [dbo].[InventoryGLSetting] (
    [InventoryGLSettingId]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [StockInventoryName]                VARCHAR (150)  NOT NULL,
    [InventoryGLAccId]                  BIGINT         NOT NULL,
    [InventoryGLAccCode]                NVARCHAR (250) NULL,
    [GoodsReceivedNotInvoicesGLAccId]   BIGINT         NOT NULL,
    [GoodsReceivedNotInvoicesGLAccCode] NVARCHAR (250) NULL,
    [WorkInProgressGLAccId]             BIGINT         NOT NULL,
    [WorkInProgressGLAccCode]           NVARCHAR (250) NULL,
    [InventoryToBillGLAccId]            BIGINT         NOT NULL,
    [InventoryToBillGLAccCode]          NVARCHAR (250) NULL,
    [FinishedGoodsGLAccId]              BIGINT         NOT NULL,
    [FinishedGoodsGLAccCode]            NVARCHAR (250) NULL,
    [InventoryExchAgreementGLAccId]     BIGINT         NOT NULL,
    [InventoryExchAgreementGLAccCode]   NVARCHAR (250) NULL,
    [InventoryReserveGLAccId]           BIGINT         NOT NULL,
    [InventoryReserveGLAccCode]         NVARCHAR (250) NULL,
    [COGS_WorkOrderGLAccId]             BIGINT         NOT NULL,
    [COGS_WorkOrderGLAccCode]           NVARCHAR (250) NULL,
    [COGS_SalesOrderGLAccId]            BIGINT         NOT NULL,
    [COGS_SalesOrderGLAccCode]          NVARCHAR (250) NULL,
    [COGS_ExchSalesOrderGLAccId]        BIGINT         NULL,
    [COGS_ExchSalesOrderGLAccCode]      NVARCHAR (250) NULL,
    [COGS_QtyVarianceGLAccId]           BIGINT         NOT NULL,
    [COGS_QtyVarianceGLAccCode]         NVARCHAR (250) NULL,
    [COGS_UnitCostVarianceGLAccId]      BIGINT         NOT NULL,
    [COGS_UnitCostVarianceGLAccCode]    NVARCHAR (250) NULL,
    [RevenueMroGLAccId]                 BIGINT         NOT NULL,
    [RevenueMroGLAccCode]               NVARCHAR (250) NULL,
    [RevenueSoGLAccId]                  BIGINT         NOT NULL,
    [RevenueSoGLAccCode]                NVARCHAR (250) NULL,
    [RevenueExchGLAccId]                BIGINT         NOT NULL,
    [RevenueExchGLAccCode]              NVARCHAR (250) NULL,
    [MasterCompanyId]                   INT            NOT NULL,
    [CreatedBy]                         VARCHAR (256)  NOT NULL,
    [UpdatedBy]                         VARCHAR (256)  NOT NULL,
    [CreatedDate]                       DATETIME       NOT NULL,
    [UpdatedDate]                       DATETIME       NOT NULL,
    [Memo]                              VARCHAR (MAX)  NULL,
    [IsActive]                          BIT            CONSTRAINT [DF__tmp_ms_xx__IsAct__5BF257F4] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                         BIT            CONSTRAINT [DF__tmp_ms_xx__IsDel__5CE67C2D] DEFAULT ((0)) NOT NULL
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