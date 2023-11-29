CREATE TABLE [dbo].[WorkflowEquipmentList] (
    [WorkflowEquipmentListId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkflowId]              BIGINT         NOT NULL,
    [AssetId]                 BIGINT         NULL,
    [AssetTypeId]             BIGINT         NULL,
    [AssetDescription]        VARCHAR (500)  NULL,
    [Quantity]                SMALLINT       NOT NULL,
    [TaskId]                  BIGINT         NOT NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NULL,
    [UpdatedBy]               VARCHAR (256)  NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_WorkflowEquipmentList_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  CONSTRAINT [DF_WorkflowEquipmentList_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_WorkflowEquipmentList_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF_WorkflowEquipmentList_IsDeleted] DEFAULT ((0)) NOT NULL,
    [PartNumber]              VARCHAR (256)  NULL,
    [Order]                   INT            NULL,
    [Memo]                    VARCHAR (1000) NULL,
    [WFParentId]              BIGINT         NULL,
    [IsVersionIncrease]       BIT            NULL,
    [AssetAttributeTypeId]    BIGINT         NULL,
    CONSTRAINT [PK_ProcessEquipmentList] PRIMARY KEY CLUSTERED ([WorkflowEquipmentListId] ASC),
    CONSTRAINT [FK_WorkflowEquipmentList_AssetId] FOREIGN KEY ([AssetId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_WorkflowEquipmentList_Task_TaskId] FOREIGN KEY ([TaskId]) REFERENCES [dbo].[Task] ([TaskId]),
    CONSTRAINT [FK_WorkflowEquipmentList_WorkflowId] FOREIGN KEY ([WorkflowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);




GO




CREATE TRIGGER [dbo].[Trg_WorkflowEquipmentListAudit]

   ON  [dbo].[WorkflowEquipmentList]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkflowEquipmentListAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END