CREATE TABLE [dbo].[History] (
    [HistoryId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleId]        BIGINT        NULL,
    [RefferenceId]    BIGINT        NULL,
    [OldValue]        VARCHAR (MAX) NOT NULL,
    [NewValue]        VARCHAR (MAX) NOT NULL,
    [HistoryText]     VARCHAR (MAX) NOT NULL,
    [FieldsName]      VARCHAR (50)  NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_History_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_History_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [SubModuleId]     BIGINT        NULL,
    [SubRefferenceId] BIGINT        NULL,
    CONSTRAINT [PK_History] PRIMARY KEY CLUSTERED ([HistoryId] ASC),
    CONSTRAINT [FK_History_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

