CREATE TABLE [dbo].[RankingAudit] (
    [RankingAuditId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [RankingId]       BIGINT         NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_RankingAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_RankingAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_RankingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_RankingAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_RankingAudit] PRIMARY KEY CLUSTERED ([RankingAuditId] ASC)
);

