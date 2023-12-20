CREATE TABLE [dbo].[Directions] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (256)  CONSTRAINT [DF__Direction__Creat__569F9A3F] DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME2 (7)  CONSTRAINT [DF_Directions_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedBy]   VARCHAR (50)   CONSTRAINT [DF__Direction__Updat__5793BE78] DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME2 (7)  CONSTRAINT [DF__Direction__Updat__5887E2B1] DEFAULT (sysdatetime()) NULL,
    [IsDeleted]   BIT            CONSTRAINT [DF__Direction__IsDel__597C06EA] DEFAULT ((0)) NULL,
    [Action]      VARCHAR (256)  NULL,
    [Description] VARCHAR (256)  NULL,
    [Sequence]    VARCHAR (256)  NULL,
    [Memo]        NVARCHAR (MAX) NULL,
    [ActionId]    BIGINT         NOT NULL,
    [WorkFlowId]  BIGINT         NOT NULL,
    [IsActive]    BIT            NOT NULL,
    CONSTRAINT [PK__Directio__3214EC0769C2A984] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Directions_Actions_ActionId] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[Action] ([ActionId]) ON DELETE CASCADE,
    CONSTRAINT [FK_Directions_WorkFlows_WorkFlowId] FOREIGN KEY ([WorkFlowId]) REFERENCES [dbo].[Workflow] ([WorkflowId]) ON DELETE CASCADE
);


GO




CREATE TRIGGER [dbo].[Trg_DirectionsAudit]

   ON  [dbo].[Directions]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO DirectionsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END