CREATE TABLE [dbo].[ATASubChapterAudit] (
    [ATASubChapterAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ATASubChapterId]      BIGINT         NOT NULL,
    [ATASubChapterCode]    VARCHAR (10)   NOT NULL,
    [Description]          VARCHAR (256)  NULL,
    [Memo]                 VARCHAR (5000) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [ATAChapterId]         BIGINT         NOT NULL,
    [ATAChapterCategoryId] INT            NOT NULL,
    [ATAChapterName]       VARCHAR (256)  NOT NULL,
    [ATAChapterCategory]   VARCHAR (256)  NOT NULL
);

