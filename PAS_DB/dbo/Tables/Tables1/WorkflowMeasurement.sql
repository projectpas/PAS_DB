CREATE TABLE [dbo].[WorkflowMeasurement] (
    [WorkflowMeasurementId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowId]            BIGINT          NOT NULL,
    [Sequence]              VARCHAR (50)    NULL,
    [Stage]                 VARCHAR (50)    NULL,
    [Min]                   DECIMAL (18, 2) CONSTRAINT [DF_WorkflowMeasurement_Min] DEFAULT ((0)) NULL,
    [Max]                   DECIMAL (18, 2) CONSTRAINT [DF_WorkflowMeasurement_Max] DEFAULT ((0)) NULL,
    [Expected]              DECIMAL (18, 2) CONSTRAINT [DF_WorkflowMeasurement_Expected] DEFAULT ((0)) NULL,
    [DiagramURL]            NVARCHAR (512)  NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [TaskId]                BIGINT          NOT NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NOT NULL,
    [UpdatedBy]             VARCHAR (256)   NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_WorkflowMeasurement_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_WorkflowMeasurement_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]              BIT             CONSTRAINT [DF_WorkflowMeasurement_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_WorkflowMeasurement_IsDeleted] DEFAULT ((0)) NULL,
    [ItemMasterId]          BIGINT          NOT NULL,
    [PartNumber]            VARCHAR (256)   NULL,
    [Order]                 INT             NULL,
    [PartDescription]       VARCHAR (MAX)   NULL,
    [WFParentId]            BIGINT          NULL,
    [IsVersionIncrease]     BIT             NULL,
    CONSTRAINT [PK_WorkflowMeasurement] PRIMARY KEY CLUSTERED ([WorkflowMeasurementId] ASC),
    CONSTRAINT [FK_MaterialLists_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkflowMeasurement_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_WorkflowMeasurement_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);




GO




CREATE TRIGGER [dbo].[Trg_WorkflowMeasurementAudit]

   ON  [dbo].[WorkflowMeasurement]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowMeasurementAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END