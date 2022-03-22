CREATE TABLE [dbo].[WorkOrderBulletinsModification] (
    [WorkOrderBulletinsModificationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTeardownId]              BIGINT         NULL,
    [Memo]                             NVARCHAR (MAX) NULL,
    [ReasonId]                         BIGINT         NULL,
    [SubWorkOrderTeardownId]           BIGINT         NULL,
    [ReasonName]                       VARCHAR (200)  NULL,
    [CreatedBy]                        VARCHAR (256)  NOT NULL,
    [UpdatedBy]                        VARCHAR (256)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]                         BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]                  INT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderBulletinsModification] PRIMARY KEY CLUSTERED ([WorkOrderBulletinsModificationId] ASC),
    CONSTRAINT [FK_WorkOrderBulletinsModification_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderBulletinsModification_Reason] FOREIGN KEY ([ReasonId]) REFERENCES [dbo].[TeardownReason] ([TeardownReasonId]),
    CONSTRAINT [FK_WorkOrderBulletinsModification_SubWorkOrderTeardown] FOREIGN KEY ([SubWorkOrderTeardownId]) REFERENCES [dbo].[SubWorkOrderTeardown] ([SubWorkOrderTeardownId]),
    CONSTRAINT [FK_WorkOrderBulletinsModification_WorkOrderTeardown] FOREIGN KEY ([WorkOrderTeardownId]) REFERENCES [dbo].[WorkOrderTeardown] ([WorkOrderTeardownId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderBulletinsModificationAudit]

   ON  [dbo].[WorkOrderBulletinsModification]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderBulletinsModificationAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END