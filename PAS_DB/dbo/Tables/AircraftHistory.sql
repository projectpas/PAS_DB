CREATE TABLE [dbo].[AircraftHistory] (
    [HistoryId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleId]        BIGINT        NULL,
    [ModuleName]      VARCHAR (100) NULL,
    [RefferenceId]    BIGINT        NULL,
    [SubModuleId]     BIGINT        NULL,
    [SubModuleName]   VARCHAR (100) NULL,
    [SubRefferenceId] BIGINT        NULL,
    [FieldsName]      VARCHAR (100) NULL,
    [OldValue]        VARCHAR (MAX) NULL,
    [NewValue]        VARCHAR (MAX) NULL,
    [HistoryText]     VARCHAR (MAX) NULL,
    [Activity]        VARCHAR (50)  NULL,
    [AcTailNum]       VARCHAR (50)  NULL,
    [AcMake]          VARCHAR (100) NULL,
    [AcModel]         VARCHAR (100) NULL,
    [SerialNum]       VARCHAR (100) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_AircraftHistory_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_AircraftHistory_UpdatedDate] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_AircraftHistory] PRIMARY KEY CLUSTERED ([HistoryId] ASC),
    CONSTRAINT [FK_AircraftHistory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE NONCLUSTERED INDEX [IX_AircraftHistory_AcTailNum]
    ON [dbo].[AircraftHistory]([AcTailNum] ASC)
    INCLUDE([ModuleId], [Activity], [CreatedDate]);


GO
CREATE NONCLUSTERED INDEX [IX_AircraftHistory_RefferenceId_ModuleId]
    ON [dbo].[AircraftHistory]([RefferenceId] ASC, [ModuleId] ASC)
    INCLUDE([SubRefferenceId], [FieldsName], [Activity], [CreatedDate]);

