CREATE TABLE [dbo].[WorkOrderFinalInspection] (
    [WorkOrderFinalInspectionId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderTeardownId]        BIGINT         NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    [InspectorId]                BIGINT         NULL,
    [InspectorDate]              DATETIME2 (7)  NULL,
    [ReasonId]                   BIGINT         NULL,
    [SubWorkOrderTeardownId]     BIGINT         NULL,
    [ReasonName]                 VARCHAR (200)  NULL,
    [InspectorName]              VARCHAR (100)  NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]            INT            DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_WorkOrderFinalInspection] PRIMARY KEY CLUSTERED ([WorkOrderFinalInspectionId] ASC),
    CONSTRAINT [FK_WorkOrderFinalInspection_Inspector] FOREIGN KEY ([InspectorId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderFinalInspection_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderFinalInspection_Reason] FOREIGN KEY ([ReasonId]) REFERENCES [dbo].[TeardownReason] ([TeardownReasonId]),
    CONSTRAINT [FK_WorkOrderFinalInspection_SubWorkOrderTeardown] FOREIGN KEY ([SubWorkOrderTeardownId]) REFERENCES [dbo].[SubWorkOrderTeardown] ([SubWorkOrderTeardownId]),
    CONSTRAINT [FK_WorkOrderFinalInspection_WorkOrderTeardown] FOREIGN KEY ([WorkOrderTeardownId]) REFERENCES [dbo].[WorkOrderTeardown] ([WorkOrderTeardownId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderFinalInspectionAudit]

   ON  [dbo].[WorkOrderFinalInspection]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderFinalInspectionAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END