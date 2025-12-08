CREATE TABLE [dbo].[WorkFlowTask] (
    [WorkFlowTaskId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkFlowId]        BIGINT         NOT NULL,
    [WorkFlowNumber]    VARCHAR (256)  NULL,
    [TaskId]            BIGINT         NOT NULL,
    [TaskDescription]   VARCHAR (200)  NULL,
    [SequenceNumber]    VARCHAR (10)   NULL,
    [Descrepancy]       NVARCHAR (MAX) NULL,
    [Resolution]        NVARCHAR (MAX) NULL,
    [IsVersionIncrease] BIT            NULL,
    [WFParentId]        BIGINT         NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_WorkFlowTask_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_WorkFlowTask_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF__WorkFlowTask__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF__WorkFlowTask__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkFlowTask] PRIMARY KEY CLUSTERED ([WorkFlowTaskId] ASC)
);






GO
CREATE TRIGGER [dbo].[Trg_WorkFlowTaskAudit]
   ON  [dbo].[WorkFlowTask]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO WorkFlowTaskAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;
END