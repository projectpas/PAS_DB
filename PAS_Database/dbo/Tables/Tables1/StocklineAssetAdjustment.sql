/*************************************************************
 ** [PN-18407] Asset and Lease Configuration in Stockline
 ** Asset Adjustment of an Asset stockline (Stockline List > Asset Adjustment).
 ** Same data as AssetInventoryAdjustment, keyed by StockLineId.
 ** AssetInventoryAdjustmentDataTypeId: 1 Management Structure, 2 Revaluation, 3 Useful Life,
 **                                     4 Asset ID, 5 Location, 6 Depreciation Expense, 7 Accumulated Depreciation
**************************************************************/
CREATE TABLE [dbo].[StocklineAssetAdjustment] (
    [StocklineAssetAdjustmentId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [StockLineId]                        BIGINT         NOT NULL,
    [AssetInventoryAdjustmentDataTypeId] INT            NOT NULL,
    [ChangedFromId]                      BIGINT         NULL,
    [ChangedToId]                        BIGINT         NULL,
    [ChangedFrom]                        VARCHAR (250)  NULL,
    [ChangedTo]                          VARCHAR (250)  NULL,
    [AdjustmentMemo]                     NVARCHAR (MAX) NULL,
    [AdjustmentReasonId]                 INT            NULL,
    [AdjustmentReason]                   VARCHAR (250)  NULL,
    [MasterCompanyId]                    INT            NOT NULL,
    [CreatedBy]                          VARCHAR (256)  NOT NULL,
    [UpdatedBy]                          VARCHAR (256)  NOT NULL,
    [CreatedDate]                        DATETIME2 (7)  CONSTRAINT [DF_StocklineAssetAdjustment_CreatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [UpdatedDate]                        DATETIME2 (7)  CONSTRAINT [DF_StocklineAssetAdjustment_UpdatedDate] DEFAULT (GETUTCDATE()) NOT NULL,
    [IsActive]                           BIT            CONSTRAINT [DF_StocklineAssetAdjustment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                          BIT            CONSTRAINT [DF_StocklineAssetAdjustment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_StocklineAssetAdjustment] PRIMARY KEY CLUSTERED ([StocklineAssetAdjustmentId] ASC),
    CONSTRAINT [FK_StocklineAssetAdjustment_Stockline] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_StocklineAssetAdjustment_DataType] FOREIGN KEY ([AssetInventoryAdjustmentDataTypeId]) REFERENCES [dbo].[AssetInventoryAdjustmentDataType] ([AssetInventoryAdjustmentDataTypeId]),
    CONSTRAINT [FK_StocklineAssetAdjustment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);
GO
CREATE NONCLUSTERED INDEX [IX_StocklineAssetAdjustment_StockLineId]
    ON [dbo].[StocklineAssetAdjustment]([StockLineId] ASC);
