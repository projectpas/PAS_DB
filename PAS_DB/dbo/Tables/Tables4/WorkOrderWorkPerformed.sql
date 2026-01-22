CREATE TABLE [dbo].[WorkOrderWorkPerformed] (
    [WorkOrderWorkPerformedId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTeardownId]      BIGINT         NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [TechnicianId]             BIGINT         NULL,
    [TechnicianDate]           DATETIME2 (7)  NULL,
    [InspectorId]              BIGINT         NULL,
    [InspectorDate]            DATETIME2 (7)  NULL,
    [ReasonId]                 BIGINT         NULL,
    [SubWorkOrderTeardownId]   BIGINT         NULL,
    [ReasonName]               VARCHAR (200)  NULL,
    [InspectorName]            VARCHAR (100)  NULL,
    [TechnicalName]            VARCHAR (100)  NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]          INT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderWorkPerformed] PRIMARY KEY CLUSTERED ([WorkOrderWorkPerformedId] ASC),
    CONSTRAINT [FK_WorkOrderWorkPerformed_Inspector] FOREIGN KEY ([InspectorId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderWorkPerformed_Reason] FOREIGN KEY ([ReasonId]) REFERENCES [dbo].[TeardownReason] ([TeardownReasonId]),
    CONSTRAINT [FK_WorkOrderWorkPerformed_SubWorkOrderTeardown] FOREIGN KEY ([SubWorkOrderTeardownId]) REFERENCES [dbo].[SubWorkOrderTeardown] ([SubWorkOrderTeardownId]),
    CONSTRAINT [FK_WorkOrderWorkPerformed_Technician] FOREIGN KEY ([TechnicianId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderWorkPerformed_WorkOrderTeardown] FOREIGN KEY ([WorkOrderTeardownId]) REFERENCES [dbo].[WorkOrderTeardown] ([WorkOrderTeardownId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderWorkPerformedAudit]

   ON  [dbo].[WorkOrderWorkPerformed]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderWorkPerformedAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END