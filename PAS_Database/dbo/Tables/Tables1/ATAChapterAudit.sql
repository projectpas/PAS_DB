CREATE TABLE [dbo].[ATAChapterAudit] (
    [ATAChapterAuditId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [ATAChapterId]         BIGINT        NOT NULL,
    [ATAChapterCode]       VARCHAR (256) NOT NULL,
    [ATAChapterName]       VARCHAR (256) NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [Memo]                 VARCHAR (MAX) NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    [ATAChapterCategoryId] INT           NOT NULL,
    [ATAChapterCategory]   VARCHAR (256) NOT NULL
);

