CREATE TABLE [dbo].[MaterialLists] (
    [Id]                      INT            IDENTITY (1, 1) NOT NULL,
    [CreatedBy]               VARCHAR (50)   CONSTRAINT [DF__MaterialL__Creat__17793963] DEFAULT (NULL) NULL,
    [CreatedDate]             DATETIME       CONSTRAINT [DF_MaterialLists_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (50)   CONSTRAINT [DF__MaterialL__Updat__186D5D9C] DEFAULT (NULL) NULL,
    [UpdatedDate]             DATETIME       CONSTRAINT [DF__MaterialL__Updat__196181D5] DEFAULT (getdate()) NULL,
    [IsDeleted]               BIT            CONSTRAINT [DF__MaterialL__IsDel__1A55A60E] DEFAULT ((0)) NULL,
    [PN]                      VARCHAR (256)  NULL,
    [Description]             VARCHAR (256)  NULL,
    [Condition]               VARCHAR (256)  NULL,
    [MandatoryOrSupplemental] VARCHAR (256)  NULL,
    [ItemClassification]      VARCHAR (256)  NULL,
    [Quantity]                VARCHAR (256)  NULL,
    [UOM]                     VARCHAR (256)  NULL,
    [UnitCost]                VARCHAR (256)  NULL,
    [ExtraCost]               VARCHAR (256)  NULL,
    [Price]                   VARCHAR (256)  NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [Deffered]                BIT            NOT NULL,
    [ActionId]                BIGINT         NOT NULL,
    [WorkFlowId]              BIGINT         NOT NULL,
    [IsActive]                BIT            CONSTRAINT [DF_MaterialLists_IsActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK__Material__3214EC07E71B4CAC] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_MaterialLists_Actions_ActionId] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[Action] ([ActionId]),
    CONSTRAINT [FK_MaterialLists_WorkFlows_WorkFlowId] FOREIGN KEY ([WorkFlowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_MaterialListsAudit]

   ON  [dbo].[MaterialLists]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MaterialListsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END