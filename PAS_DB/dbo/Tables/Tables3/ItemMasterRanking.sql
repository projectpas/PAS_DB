CREATE TABLE [dbo].[ItemMasterRanking] (
    [ItemMasterRankingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]        BIGINT        NOT NULL,
    [RankingId]           INT           NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NULL,
    [UpdatedBy]           VARCHAR (256) NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) NOT NULL,
    [IsActive]            BIT           NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_ItemMasterRanking_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ItemMasterRanking] PRIMARY KEY CLUSTERED ([ItemMasterRankingId] ASC)
);
GO
CREATE NONCLUSTERED INDEX [IX_ItemMasterRanking_ItemMasterId_Perf]
    ON [dbo].[ItemMasterRanking]([ItemMasterId] ASC)
    INCLUDE([RankingId]) WITH (FILLFACTOR = 90, DATA_COMPRESSION = PAGE);
-- Added 2026-08-03: supports ProcItemMasterStockList's per-item Ranking STRING_AGG rollup (see
-- ProcItemMasterStockList_Performance_Recommendations.sql for the full review).


GO
CREATE NONCLUSTERED INDEX [IX_ItemMasterRanking_IM]
    ON [dbo].[ItemMasterRanking]([ItemMasterId] ASC, [RankingId] ASC);


GO
CREATE NONCLUSTERED INDEX [IX_ItemMasterRanking]
    ON [dbo].[ItemMasterRanking]([ItemMasterId] ASC)
    INCLUDE([RankingId]);

