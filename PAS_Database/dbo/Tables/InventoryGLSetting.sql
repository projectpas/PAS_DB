CREATE TABLE [dbo].[InventoryGLSetting] (
    [InventoryGLSettingId]            BIGINT        IDENTITY (1, 1) NOT NULL,
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
    [IsActive]                        BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           DEFAULT ((0)) NOT NULL
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
            InventoryGLAccId,
            GoodsReceivedNotInvoicesGLAccId,
            WorkInProgressGLAccId,
            InventoryToBillGLAccId,
            FinishedGoodsGLAccId,
            InventoryExchAgreementGLAccId,
            InventoryReserveGLAccId,
            COGS_WorkOrderGLAccId,
            COGS_SalesOrderGLAccId,
            COGS_QtyVarianceGLAccId,
            COGS_UnitCostVarianceGLAccId,
            RevenueMroGLAccId,
            RevenueSoGLAccId,
            RevenueMiscGLAccId,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            UpdatedDate,
            IsActive,
            IsDeleted
        )
        SELECT
            InventoryGLSettingId,
            InventoryGLAccId,
            GoodsReceivedNotInvoicesGLAccId,
            WorkInProgressGLAccId,
            InventoryToBillGLAccId,
            FinishedGoodsGLAccId,
            InventoryExchAgreementGLAccId,
            InventoryReserveGLAccId,
            COGS_WorkOrderGLAccId,
            COGS_SalesOrderGLAccId,
            COGS_QtyVarianceGLAccId,
            COGS_UnitCostVarianceGLAccId,
            RevenueMroGLAccId,
            RevenueSoGLAccId,
            RevenueMiscGLAccId,
            MasterCompanyId,
            CreatedBy,
            UpdatedBy,
            CreatedDate,
            GETUTCDATE(),
            IsActive,
            IsDeleted
        FROM inserted;
    END

END