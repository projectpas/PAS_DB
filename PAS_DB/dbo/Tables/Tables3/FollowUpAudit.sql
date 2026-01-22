CREATE TABLE [dbo].[FollowUpAudit] (
    [AuditFollowUpId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FollowUpId]      BIGINT         NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [ModuleId]        INT            NOT NULL,
    [Subject]         VARCHAR (256)  NULL,
    [EntryDate]       DATETIME2 (7)  NULL,
    [FollowUpDate]    DATETIME2 (7)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            NOT NULL,
    [IsDeleted]       BIT            NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_CRMFollowUpAudit] PRIMARY KEY CLUSTERED ([AuditFollowUpId] ASC)
);

