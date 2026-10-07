CREATE TABLE [dbo].[TaskInstructionImage] (
    [TaskInstructionImageId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [TaskInstructionId]      BIGINT          NOT NULL,
    [FileName]               VARCHAR (500)   NULL,
    [Link]                   VARCHAR (1000)  NULL,
    [FileType]               VARCHAR (100)   NULL,
    [FileSize]               DECIMAL (18, 2) NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (100)   NOT NULL,
    [UpdatedBy]              VARCHAR (100)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_TaskInstructionImage_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_TaskInstructionImage_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [DF_TaskInstructionImage_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_TaskInstructionImage_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TaskInstructionImage] PRIMARY KEY CLUSTERED ([TaskInstructionImageId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_TaskInstructionImage_TaskInstructionId]
    ON [dbo].[TaskInstructionImage]([TaskInstructionId] ASC)
    INCLUDE([FileName], [Link], [FileType], [FileSize], [IsActive], [IsDeleted]);

