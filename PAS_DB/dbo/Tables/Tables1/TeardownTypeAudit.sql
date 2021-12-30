CREATE TABLE [dbo].[TeardownTypeAudit] (
    [TeardownTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TeardownTypeId]      BIGINT        NOT NULL,
    [Name]                VARCHAR (256) NOT NULL,
    [Description]         VARCHAR (MAX) NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) NOT NULL,
    [IsActive]            BIT           NOT NULL,
    [IsDeleted]           BIT           NOT NULL,
    [TearDownCode]        VARCHAR (200) NULL,
    [Sequence]            INT           NULL,
    CONSTRAINT [PK_TeardownTypeAudit] PRIMARY KEY CLUSTERED ([TeardownTypeAuditId] ASC)
);



