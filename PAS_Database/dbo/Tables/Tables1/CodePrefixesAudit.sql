CREATE TABLE [dbo].[CodePrefixesAudit] (
    [AuditCodePrefixId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CodePrefixId]      BIGINT         NOT NULL,
    [CodeTypeId]        BIGINT         NOT NULL,
    [CurrentNummber]    BIGINT         NULL,
    [CodePrefix]        VARCHAR (10)   NOT NULL,
    [CodeSufix]         VARCHAR (10)   NULL,
    [StartsFrom]        BIGINT         NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [Description]       VARCHAR (250)  DEFAULT ('') NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [CodeType]          VARCHAR (100)  NULL,
    CONSTRAINT [PK_CodePrefixesAudit] PRIMARY KEY CLUSTERED ([AuditCodePrefixId] ASC)
);

