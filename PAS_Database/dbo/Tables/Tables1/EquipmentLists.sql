CREATE TABLE [dbo].[EquipmentLists] (
    [Id]               INT           IDENTITY (1, 1) NOT NULL,
    [CreatedBy]        VARCHAR (50)  CONSTRAINT [DF__Equipment__Creat__6D82FF97] DEFAULT (NULL) NULL,
    [CreatedDate]      DATETIME      NOT NULL,
    [UpdatedBy]        VARCHAR (50)  CONSTRAINT [DF__Equipment__Updat__6E7723D0] DEFAULT (NULL) NULL,
    [UpdatedDate]      DATETIME      CONSTRAINT [DF__Equipment__Updat__6F6B4809] DEFAULT (NULL) NULL,
    [IsDeleted]        BIT           CONSTRAINT [DF__Equipment__IsDel__705F6C42] DEFAULT (NULL) NULL,
    [AssetId]          VARCHAR (256) NULL,
    [AssetType]        VARCHAR (256) NULL,
    [AssetDescription] VARCHAR (256) NULL,
    [Quantity]         VARCHAR (256) NULL,
    [ActionId]         BIGINT        NOT NULL,
    [WorkFlowId]       BIGINT        NOT NULL,
    CONSTRAINT [PK__Equipmen__3214EC070861036D] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_EquipmentLists_Actions_ActionId] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[Action] ([ActionId]),
    CONSTRAINT [FK_EquipmentLists_WorkFlows_WorkFlowId] FOREIGN KEY ([WorkFlowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_EquipmentListsAudit]

   ON  [dbo].[EquipmentLists]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO EquipmentListsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END