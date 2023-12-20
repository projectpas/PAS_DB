CREATE TABLE [dbo].[Expertises] (
    [Id]               INT           IDENTITY (1, 1) NOT NULL,
    [CreatedBy]        VARCHAR (50)  CONSTRAINT [DF__Expertise__Creat__027E1C7D] DEFAULT (NULL) NULL,
    [CreatedDate]      DATETIME      NOT NULL,
    [UpdatedBy]        VARCHAR (50)  CONSTRAINT [DF__Expertise__Updat__037240B6] DEFAULT (NULL) NULL,
    [UpdatedDate]      DATETIME      CONSTRAINT [DF__Expertise__Updat__046664EF] DEFAULT (NULL) NULL,
    [IsDeleted]        BIT           CONSTRAINT [DF__Expertise__IsDel__055A8928] DEFAULT (NULL) NULL,
    [ExpertiseType]    VARCHAR (256) NULL,
    [EstimatedHours]   VARCHAR (256) NULL,
    [LabourDirectRate] VARCHAR (256) NULL,
    [LabourDirectCost] VARCHAR (256) NULL,
    [OHeadBurden]      VARCHAR (256) NULL,
    [OHCost]           VARCHAR (256) NULL,
    [LabourAndOHCost]  VARCHAR (256) NULL,
    [ActionId]         BIGINT        NOT NULL,
    [WorkFlowId]       BIGINT        NOT NULL,
    CONSTRAINT [PK__Expertis__3214EC07AD91BFC2] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Expertises_Actions_ActionId] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[Action] ([ActionId]),
    CONSTRAINT [FK_Expertises_WorkFlows_WorkFlowId] FOREIGN KEY ([WorkFlowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExpertisesAudit]

   ON  [dbo].[Expertises]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExpertisesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END