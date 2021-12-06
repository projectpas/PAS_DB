CREATE TABLE [dbo].[WorkflowPublications] (
    [WorkflowPublicationsId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [CreatedBy]              VARCHAR (50)   NULL,
    [CreatedDate]            DATETIME       CONSTRAINT [DF_Publications_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]              VARCHAR (50)   NULL,
    [UpdatedDate]            DATETIME       CONSTRAINT [DF_Publications_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_Publications_IsDeleted] DEFAULT ((0)) NULL,
    [PublicationId]          BIGINT         NULL,
    [PublicationDescription] VARCHAR (256)  NULL,
    [PublicationType]        VARCHAR (256)  NULL,
    [Sequence]               VARCHAR (256)  NULL,
    [Source]                 VARCHAR (256)  NULL,
    [AircraftManufacturer]   INT            NULL,
    [Model]                  BIGINT         NULL,
    [Location]               VARCHAR (256)  NULL,
    [Revision]               VARCHAR (256)  NULL,
    [RevisionDate]           VARCHAR (256)  NULL,
    [VerifiedBy]             VARCHAR (256)  NULL,
    [VerifiedDate]           VARCHAR (256)  NULL,
    [Status]                 VARCHAR (256)  NULL,
    [Image]                  VARCHAR (256)  NULL,
    [TaskId]                 BIGINT         NOT NULL,
    [WorkflowId]             BIGINT         NOT NULL,
    [MasterCompanyId]        INT            NULL,
    [Order]                  INT            NULL,
    [IsActive]               BIT            CONSTRAINT [DF_Publications_IsActive] DEFAULT ((1)) NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [WFParentId]             BIGINT         NULL,
    [IsVersionIncrease]      BIT            NULL,
    PRIMARY KEY CLUSTERED ([WorkflowPublicationsId] ASC),
    CONSTRAINT [FK_Publications_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkflowPublications_PublicationId] FOREIGN KEY ([PublicationId]) REFERENCES [dbo].[Publication] ([PublicationRecordId]),
    CONSTRAINT [FK_WorkflowPublications_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowPublicationsAudit]

   ON  [dbo].[WorkflowPublications]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowPublicationsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END