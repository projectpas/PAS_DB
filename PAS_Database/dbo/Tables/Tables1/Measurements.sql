CREATE TABLE [dbo].[Measurements] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50)   CONSTRAINT [DF__Measureme__Creat__2C745649] DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME       CONSTRAINT [DF_Measurements_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]   VARCHAR (50)   CONSTRAINT [DF__Measureme__Updat__2D687A82] DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME       CONSTRAINT [DF__Measureme__Updat__2E5C9EBB] DEFAULT (getdate()) NULL,
    [IsDeleted]   BIT            CONSTRAINT [DF__Measureme__IsDel__2F50C2F4] DEFAULT ((0)) NULL,
    [PN]          VARCHAR (256)  NULL,
    [Sequence]    VARCHAR (256)  NULL,
    [Stage]       VARCHAR (256)  NULL,
    [Min]         VARCHAR (256)  NULL,
    [Max]         VARCHAR (256)  NULL,
    [Expected]    VARCHAR (256)  NULL,
    [Diagram]     VARCHAR (256)  NULL,
    [Memo]        NVARCHAR (MAX) NULL,
    [ActionId]    BIGINT         NOT NULL,
    [WorkFlowId]  BIGINT         NOT NULL,
    CONSTRAINT [PK__Measurem__3214EC07D8212261] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Measurements_Actions_ActionId] FOREIGN KEY ([ActionId]) REFERENCES [dbo].[Action] ([ActionId]),
    CONSTRAINT [FK_Measurements_WorkFlows_WorkFlowId] FOREIGN KEY ([WorkFlowId]) REFERENCES [dbo].[Workflow] ([WorkflowId])
);

