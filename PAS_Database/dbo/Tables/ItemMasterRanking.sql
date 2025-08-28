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

