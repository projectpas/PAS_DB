CREATE TABLE [dbo].[ActivityType] (
    [ActivityTypeId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [ActivityTypeName] VARCHAR (256)   NOT NULL,
    [Sequence]         INT             NOT NULL,
    [Points]           DECIMAL (10, 2) NOT NULL,
    [MasterCompanyId]  INT             NOT NULL,
    [CreatedBy]        VARCHAR (256)   NOT NULL,
    [UpdatedBy]        VARCHAR (256)   NOT NULL,
    [CreatedDate]      DATETIME2 (7)   CONSTRAINT [ActivityType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)   CONSTRAINT [ActivityType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT             CONSTRAINT [ActivityType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT             CONSTRAINT [ActivityType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ActivityType] PRIMARY KEY CLUSTERED ([ActivityTypeId] ASC),
    CONSTRAINT [FK_ActivityType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ActivityType] UNIQUE NONCLUSTERED ([ActivityTypeName] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_ActivityTypeSeqNo] UNIQUE NONCLUSTERED ([Sequence] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ActivityTypeAudit]

   ON  [dbo].[ActivityType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ActivityTypeAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END