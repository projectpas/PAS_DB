CREATE TABLE [dbo].[WorkOrderTaskAttribute] (
    [WorkOrderTaskAttributeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [WorkOrderTaskId]          BIGINT        NOT NULL,
    [TaskAttributeId]          BIGINT        NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_WorkOrderTaskAttribute_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_WorkOrderTaskAttribute_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_WorkOrderTaskAttribute_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF_WorkOrderTaskAttribute_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkOrderTaskAttribute] PRIMARY KEY CLUSTERED ([WorkOrderTaskAttributeId] ASC),
    CONSTRAINT [FK_WorkOrderTaskAttribute_WorkOrderTask] FOREIGN KEY ([WorkOrderTaskId]) REFERENCES [dbo].[WorkOrderTask] ([WorkOrderTaskId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderTaskAttributeAudit]

   ON  [dbo].[WorkOrderTaskAttribute]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderTaskAttributeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END