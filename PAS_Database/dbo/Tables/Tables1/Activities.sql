CREATE TABLE [dbo].[Activities] (
    [ActivitiesId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [ActivityName]    VARCHAR (256)  NOT NULL,
    [Title]           VARCHAR (256)  NULL,
    [ActivityTypeId]  BIGINT         NULL,
    [Contact]         VARCHAR (256)  NULL,
    [Subject]         VARCHAR (256)  NULL,
    [EntryDate]       DATETIME2 (7)  NULL,
    [FollowUpDate]    DATETIME2 (7)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [CRMActivities_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [CRMActivities_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [CRMActivities_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [CRMActivities_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [ModuleId]        INT            NULL,
    [Description]     NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_CRMActivity] PRIMARY KEY CLUSTERED ([ActivitiesId] ASC),
    CONSTRAINT [FK_Activities_Module] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[Module] ([ModuleId]),
    CONSTRAINT [FK_CRMActivities_ActivityType] FOREIGN KEY ([ActivityTypeId]) REFERENCES [dbo].[ActivityType] ([ActivityTypeId]),
    CONSTRAINT [FK_CRMActivities_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_CRMActivities] UNIQUE NONCLUSTERED ([ActivityName] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_ActivitiesAudit]

   ON  [dbo].[Activities]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ActivitiesAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END