CREATE TABLE [dbo].[JobTitleAudit] (
    [JobTitleAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [JobTitleId]      SMALLINT       NOT NULL,
    [Description]     VARCHAR (30)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [JobTitleCode]    VARCHAR (50)   NULL,
    CONSTRAINT [PK_JobTitleAudit] PRIMARY KEY CLUSTERED ([JobTitleAuditId] ASC)
);

