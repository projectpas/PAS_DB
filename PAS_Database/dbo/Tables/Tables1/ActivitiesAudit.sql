CREATE TABLE [dbo].[ActivitiesAudit] (
    [AuditActivitiesId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ActivitiesId]      BIGINT         NOT NULL,
    [ActivityName]      VARCHAR (256)  NOT NULL,
    [Title]             VARCHAR (256)  NULL,
    [ActivityTypeId]    BIGINT         NULL,
    [Contact]           VARCHAR (256)  NULL,
    [Subject]           VARCHAR (256)  NULL,
    [EntryDate]         DATETIME2 (7)  NULL,
    [FollowUpDate]      DATETIME2 (7)  NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [ReferenceId]       BIGINT         NOT NULL,
    [ModuleId]          INT            NULL,
    [Description]       NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_CRMActivityAudit] PRIMARY KEY CLUSTERED ([AuditActivitiesId] ASC)
);

