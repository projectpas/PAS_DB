CREATE TABLE [dbo].[WorkOrderDiscovery] (
    [WorkOrderDiscoveryId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTeardownId]    BIGINT         NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [TechnicianId]           BIGINT         NULL,
    [TechnicianDate]         DATETIME2 (7)  NULL,
    [InspectorId]            BIGINT         NULL,
    [InspectorDate]          DATETIME2 (7)  NULL,
    [ReasonId]               BIGINT         NULL,
    [SubWorkOrderTeardownId] BIGINT         NULL,
    [InspectorName]          VARCHAR (100)  NULL,
    [TechnicalName]          VARCHAR (100)  NULL,
    [ReasonName]             VARCHAR (200)  NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]        INT            DEFAULT ((1)) NOT NULL,
    [IsDocument]             BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderDiscovery] PRIMARY KEY CLUSTERED ([WorkOrderDiscoveryId] ASC),
    CONSTRAINT [FK_WorkOrderDiscovery_Inspector] FOREIGN KEY ([InspectorId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderDiscovery_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderDiscovery_Reason] FOREIGN KEY ([ReasonId]) REFERENCES [dbo].[TeardownReason] ([TeardownReasonId]),
    CONSTRAINT [FK_WorkOrderDiscovery_SubWorkOrderTeardown] FOREIGN KEY ([SubWorkOrderTeardownId]) REFERENCES [dbo].[SubWorkOrderTeardown] ([SubWorkOrderTeardownId]),
    CONSTRAINT [FK_WorkOrderDiscovery_Technician] FOREIGN KEY ([TechnicianId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderDiscovery_WorkOrderTeardown] FOREIGN KEY ([WorkOrderTeardownId]) REFERENCES [dbo].[WorkOrderTeardown] ([WorkOrderTeardownId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderDiscoveryAudit]

   ON  [dbo].[WorkOrderDiscovery]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderDiscoveryAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END