CREATE TABLE [dbo].[OpenAIPrompt] (
    [PromptId]        BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100) NOT NULL,
    [PromptText]      VARCHAR (MAX) NULL,
    [Model]           NVARCHAR (50) NULL,
    [APIUrl]          VARCHAR (200) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_OpenAIPrompt_CreatedDate_1] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_OpenAIPrompt_UpdatedDate_1] DEFAULT (getutcdate()) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_OpenAIPrompt_IsDeleted_1] DEFAULT ((0)) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_OpenAIPrompt_IsActive_1] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_OpenAIPrompt] PRIMARY KEY CLUSTERED ([PromptId] ASC)
);

