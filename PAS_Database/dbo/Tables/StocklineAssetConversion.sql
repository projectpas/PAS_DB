CREATE TABLE [dbo].[StocklineAssetConversion] (
    [StocklineAssetConversionId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [SourceStockLineId]          BIGINT          NOT NULL,
    [SourceStockLineNumber]      NVARCHAR (100)  NULL,
    [SourceItemMasterId]         BIGINT          NULL,
    [SourcePartNumber]           NVARCHAR (250)  NULL,
    [BaseNum]                    NVARCHAR (100)  NULL,
    [PNType]                     NVARCHAR (100)  NULL,
    [NewStockLineId]             BIGINT          NULL,
    [NewStockLineNumber]         NVARCHAR (100)  NULL,
    [NewItemMasterId]            BIGINT          NULL,
    [NewPartNumber]              NVARCHAR (250)  NULL,
    [ConversionDate]             DATETIME2 (7)   NOT NULL,
    [AccountingCalendarId]       BIGINT          NULL,
    [AccountingPeriod]           VARCHAR (100)   NULL,
    [Cost]                       DECIMAL (18, 6) NOT NULL,
    [AccumulatedDepr]            DECIMAL (18, 6) NOT NULL,
    [NetBookValue]               DECIMAL (18, 6) NOT NULL,
    [TransferValue]              DECIMAL (18, 6) NOT NULL,
    [ValueOverNBV]               DECIMAL (18, 6) NOT NULL,
    [GainLossType]               VARCHAR (10)    NOT NULL,
    [JournalBatchHeaderId]       BIGINT          NULL,
    [JournalBatchDetailId]       BIGINT          NULL,
    [JournalTypeNumber]          VARCHAR (100)   NULL,
    [Memo]                       NVARCHAR (MAX)  NULL,
    [LegalEntityId]              BIGINT          NULL,
    [ManagementStructureId]      BIGINT          NULL,
    [MasterCompanyId]            INT             NOT NULL,
    [CreatedBy]                  VARCHAR (256)   NOT NULL,
    [UpdatedBy]                  VARCHAR (256)   NOT NULL,
    [CreatedDate]                DATETIME2 (7)   CONSTRAINT [DF_StocklineAssetConversion_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)   CONSTRAINT [DF_StocklineAssetConversion_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                   BIT             CONSTRAINT [DF_StocklineAssetConversion_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT             CONSTRAINT [DF_StocklineAssetConversion_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_StocklineAssetConversion] PRIMARY KEY CLUSTERED ([StocklineAssetConversionId] ASC),
    CONSTRAINT [FK_StocklineAssetConversion_SourceStockline] FOREIGN KEY ([SourceStockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_StocklineAssetConversion_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE NONCLUSTERED INDEX [IX_StocklineAssetConversion_SourceStockLineId]
    ON [dbo].[StocklineAssetConversion]([SourceStockLineId] ASC)
    INCLUDE([NewStockLineId], [IsDeleted]);

