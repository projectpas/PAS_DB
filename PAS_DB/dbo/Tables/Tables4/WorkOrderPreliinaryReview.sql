CREATE TABLE [dbo].[WorkOrderPreliinaryReview] (
    [WorkOrderPreliinaryReviewId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTeardownId]         BIGINT         NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [InspectorId]                 BIGINT         NULL,
    [InspectorDate]               DATETIME2 (7)  NULL,
    [ReasonId]                    BIGINT         NULL,
    [SubWorkOrderTeardownId]      BIGINT         NULL,
    [ReasonName]                  VARCHAR (200)  NULL,
    [InspectorName]               VARCHAR (100)  NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]             INT            DEFAULT ((1)) NOT NULL,
    [IsDocument]                  BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderPreliinaryReview] PRIMARY KEY CLUSTERED ([WorkOrderPreliinaryReviewId] ASC),
    CONSTRAINT [FK_WorkOrderPreliinaryReview_Inspector] FOREIGN KEY ([InspectorId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderPreliinaryReview_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderPreliinaryReview_Reason] FOREIGN KEY ([ReasonId]) REFERENCES [dbo].[TeardownReason] ([TeardownReasonId]),
    CONSTRAINT [FK_WorkOrderPreliinaryReview_SubWorkOrderTeardown] FOREIGN KEY ([SubWorkOrderTeardownId]) REFERENCES [dbo].[SubWorkOrderTeardown] ([SubWorkOrderTeardownId]),
    CONSTRAINT [FK_WorkOrderPreliinaryReview_WorkOrderTeardown] FOREIGN KEY ([WorkOrderTeardownId]) REFERENCES [dbo].[WorkOrderTeardown] ([WorkOrderTeardownId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderPreliinaryReviewAudit]

   ON  [dbo].[WorkOrderPreliinaryReview]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderPreliinaryReviewAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END