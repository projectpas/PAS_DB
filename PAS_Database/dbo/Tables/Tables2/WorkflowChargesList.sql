CREATE TABLE [dbo].[WorkflowChargesList] (
    [WorkflowChargesListId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowId]            BIGINT          NOT NULL,
    [WorkflowChargeTypeId]  TINYINT         NOT NULL,
    [Description]           VARCHAR (500)   NULL,
    [Quantity]              SMALLINT        NULL,
    [UnitCost]              DECIMAL (18, 2) NULL,
    [ExtendedCost]          DECIMAL (18, 2) NULL,
    [UnitPrice]             DECIMAL (18, 2) NULL,
    [ExtendedPrice]         DECIMAL (18, 2) NULL,
    [VendorId]              BIGINT          NULL,
    [TaskId]                BIGINT          NOT NULL,
    [MasterCompanyId]       INT             NOT NULL,
    [CreatedBy]             VARCHAR (256)   NULL,
    [UpdatedBy]             VARCHAR (256)   NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_WorkflowChargesList_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_WorkflowChargesList_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]              BIT             CONSTRAINT [DF_WorkflowChargesList_IsActive] DEFAULT ((1)) NULL,
    [VendorName]            VARCHAR (256)   NULL,
    [Order]                 INT             NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_WorkflowChargesList_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Memo]                  NVARCHAR (MAX)  NULL,
    [WFParentId]            BIGINT          NULL,
    [IsVersionIncrease]     BIT             NULL,
    CONSTRAINT [PK_ProcessChargesList] PRIMARY KEY CLUSTERED ([WorkflowChargesListId] ASC),
    CONSTRAINT [FK_WorkflowChargesList_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkflowChargesList_VendorId] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_WorkflowChargesList_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkflowChargesListAudit]

   ON  [dbo].[WorkflowChargesList]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowChargesListAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END