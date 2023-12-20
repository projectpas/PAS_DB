CREATE TABLE [dbo].[WorkOrderRemovalReasons] (
    [WorkOrderRemovalReasonsId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTeardownId]       BIGINT         NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [ReasonId]                  BIGINT         NULL,
    [SubWorkOrderTeardownId]    BIGINT         NULL,
    [ReasonName]                VARCHAR (200)  NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]           INT            DEFAULT ((1)) NOT NULL,
    [IsDocument]                BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderRemovalReasons] PRIMARY KEY CLUSTERED ([WorkOrderRemovalReasonsId] ASC),
    CONSTRAINT [FK_WorkOrderRemovalReasons_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderRemovalReasons_Reason] FOREIGN KEY ([ReasonId]) REFERENCES [dbo].[TeardownReason] ([TeardownReasonId]),
    CONSTRAINT [FK_WorkOrderRemovalReasons_SubWorkOrderTeardown] FOREIGN KEY ([SubWorkOrderTeardownId]) REFERENCES [dbo].[SubWorkOrderTeardown] ([SubWorkOrderTeardownId]),
    CONSTRAINT [FK_WorkOrderRemovalReasons_WorkOrderTeardown] FOREIGN KEY ([WorkOrderTeardownId]) REFERENCES [dbo].[WorkOrderTeardown] ([WorkOrderTeardownId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderRemovalReasonsAudit]

   ON  [dbo].[WorkOrderRemovalReasons]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderRemovalReasonsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END