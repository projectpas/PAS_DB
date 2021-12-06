CREATE TABLE [dbo].[Exclusions] (
    [Id]                        INT            IDENTITY (1, 1) NOT NULL,
    [CreatedBy]                 VARCHAR (50)   CONSTRAINT [DF__Exclusion__Creat__7ADCFAB5] DEFAULT (NULL) NULL,
    [CreatedDate]               DATETIME       CONSTRAINT [DF_Exclusions_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                 VARCHAR (50)   CONSTRAINT [DF__Exclusion__Updat__7BD11EEE] DEFAULT (NULL) NULL,
    [UpdatedDate]               DATETIME       CONSTRAINT [DF__Exclusion__Updat__7CC54327] DEFAULT (getdate()) NULL,
    [IsDeleted]                 BIT            CONSTRAINT [DF__Exclusion__IsDel__7DB96760] DEFAULT ((0)) NULL,
    [EPN]                       VARCHAR (256)  NULL,
    [EPNDescription]            VARCHAR (256)  NULL,
    [UnitCost]                  VARCHAR (256)  NULL,
    [Quantity]                  VARCHAR (256)  NULL,
    [Extended]                  VARCHAR (256)  NULL,
    [EstimatedPercentOccurance] VARCHAR (256)  NULL,
    [Memo]                      NVARCHAR (MAX) NULL,
    [ActionId]                  BIGINT         NOT NULL,
    [WorkFlowId]                BIGINT         NOT NULL,
    [IsActive]                  BIT            CONSTRAINT [DF_Exclusions_IsActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK__Exclusio__3214EC07FB9E86AA] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Exclusions_Actions_ActionId] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[Action] ([ActionId]),
    CONSTRAINT [FK_Exclusions_WorkFlows_WorkFlowId] FOREIGN KEY ([WorkFlowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);


GO




CREATE TRIGGER [dbo].[Trg_ExclusionsAudit]

   ON  [dbo].[Exclusions]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExclusionsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END