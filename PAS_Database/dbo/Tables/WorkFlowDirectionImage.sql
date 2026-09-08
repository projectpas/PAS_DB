CREATE TABLE [dbo].[WorkFlowDirectionImage] (
    [WorkflowDirectionImageId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkflowDirectionId]      BIGINT          NOT NULL,
    [WorkflowId]               BIGINT          NULL,
    [TaskId]                   BIGINT          NULL,
    [WorkFlowTaskId]           BIGINT          NULL,
    [FileName]                 VARCHAR (500)   NULL,
    [Link]                     VARCHAR (1000)  NULL,
    [FileType]                 VARCHAR (100)   NULL,
    [FileSize]                 DECIMAL (18, 2) NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (100)   NOT NULL,
    [UpdatedBy]                VARCHAR (100)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_WorkFlowDirectionImage_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_WorkFlowDirectionImage_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_WorkFlowDirectionImage_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_WorkFlowDirectionImage_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkFlowDirectionImage] PRIMARY KEY CLUSTERED ([WorkflowDirectionImageId] ASC),
    CONSTRAINT [FK_WorkFlowDirectionImage_WorkFlowDirection] FOREIGN KEY ([WorkflowDirectionId]) REFERENCES [dbo].[WorkFlowDirection] ([WorkflowDirectionId])
);

GO
CREATE NONCLUSTERED INDEX [IX_WorkFlowDirectionImage_WorkflowDirectionId]
    ON [dbo].[WorkFlowDirectionImage]([WorkflowDirectionId] ASC)
    INCLUDE([FileName], [Link], [FileType], [FileSize], [IsActive], [IsDeleted]);
