/*************************************************************
 ** File:   [StocklineAssetDepreciationHistory]
 ** Description: Lease Asset Depreciation - one row per Stockline asset (Stockline.IsAsset = 1, IsLease = 1) per Accounting Period.
 **              Same shape as AssetDepreciationHistory (Asset Inventory) but keyed on StockLineId - the Asset module tables are not touched.
 **              Written by USP_SaveStocklineAssetDepreciation (Run Process), read by USP_GetStocklineAssetDepreciableList and the Lease Asset Register.
 ** Date:   11-NOV-2026
 ** Author:  Kishor Makwana
 **************************************************************
 ** Change History
 **************************************************************
 ** PR   Date         Author		Change Description
 ** --   --------     -------		--------------------------------
    1    11-NOV-2026  Kishor Makwana    [Lease Asset Depreciation] Created
************************************************************************/
CREATE TABLE [dbo].[StocklineAssetDepreciationHistory] (
    [StocklineAssetDepreciationHistoryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [StockLineId]                         BIGINT          NOT NULL,
    [StockLineNumber]                     NVARCHAR (100)  NULL,
    [SerialNumber]                        NVARCHAR (100)  NULL,
    [PartNumber]                          NVARCHAR (250)  NULL,
    [AssetName]                           NVARCHAR (100)  NULL,
    [InServiceDate]                       DATETIME2 (7)   NULL,
    [DepreciationStartDate]               DATETIME2 (7)   NULL,
    [DepreciableStatus]                   VARCHAR (30)    NULL,
    [Currency]                            NVARCHAR (50)   NULL,
    [DepreciableLife]                     INT             NULL,
    [DepreciationMethod]                  NVARCHAR (250)  NULL,
    [DepreciationFrequency]               NVARCHAR (250)  NULL,
    [ResidualPercentage]                  DECIMAL (18, 6) NULL,
    [InstalledCost]                       DECIMAL (18, 6) NULL,
    [DepreciationAmount]                  DECIMAL (18, 6) NULL,
    [AccumulatedDepr]                     DECIMAL (18, 6) NULL,
    [NetBookValue]                        DECIMAL (18, 6) NULL,
    [NBVAfterDepreciation]                DECIMAL (18, 6) NULL,
    [LastDeprRunPeriod]                   VARCHAR (100)   NULL,
    [AccountingCalendarId]                BIGINT          NULL,
    [LegalEntityId]                       BIGINT          NULL,
    [ManagementStructureId]               BIGINT          NULL,
    [JournalBatchHeaderId]                BIGINT          NULL,
    [MasterCompanyId]                     INT             NOT NULL,
    [CreatedBy]                           VARCHAR (256)   NOT NULL,
    [UpdatedBy]                           VARCHAR (256)   NOT NULL,
    [CreatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_StocklineAssetDepreciationHistory_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7)   CONSTRAINT [DF_StocklineAssetDepreciationHistory_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                            BIT             CONSTRAINT [DF_StocklineAssetDepreciationHistory_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT             CONSTRAINT [DF_StocklineAssetDepreciationHistory_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LeaseDurationHrs]                    DECIMAL (18, 2) NULL,
    [DepreciationPerHour]                 DECIMAL (18, 6) NULL,
    [UsageHours]                          DECIMAL (18, 6) NULL,
    CONSTRAINT [PK_StocklineAssetDepreciationHistory] PRIMARY KEY CLUSTERED ([StocklineAssetDepreciationHistoryId] ASC),
    CONSTRAINT [FK_StocklineAssetDepreciationHistory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_StocklineAssetDepreciationHistory_Stockline] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId])
);




GO
-- one depreciation row per stockline per accounting period (the Run Process skips a period that was already run)
CREATE UNIQUE NONCLUSTERED INDEX [UX_StocklineAssetDepreciationHistory_Stockline_Period]
    ON [dbo].[StocklineAssetDepreciationHistory] ([StockLineId] ASC, [AccountingCalendarId] ASC)
    WHERE [IsDeleted] = 0 AND [AccountingCalendarId] IS NOT NULL;


GO
CREATE NONCLUSTERED INDEX [IX_StocklineAssetDepreciationHistory_StockLineId]
    ON [dbo].[StocklineAssetDepreciationHistory] ([StockLineId] ASC, [StocklineAssetDepreciationHistoryId] DESC)
    INCLUDE ([AccumulatedDepr], [NetBookValue], [DepreciationAmount], [LastDeprRunPeriod], [IsDeleted]);
