CREATE TABLE [dbo].[DealStageAudit] (
    [AuditDealStageId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [DealStageId]      BIGINT        NOT NULL,
    [DealStageName]    VARCHAR (256) NOT NULL,
    [Sequence]         INT           NOT NULL,
    [DealStatus]       VARCHAR (50)  NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    [IsActive]         BIT           NOT NULL,
    [IsDeleted]        BIT           NOT NULL,
    CONSTRAINT [PK_DealStageAudit] PRIMARY KEY CLUSTERED ([AuditDealStageId] ASC)
);

