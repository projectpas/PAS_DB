CREATE TABLE [dbo].[HistoryTemplate] (
    [HistoryTemplateId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TemplateCode]      VARCHAR (256) NOT NULL,
    [TemplateBody]      VARCHAR (MAX) NOT NULL,
    [TemplateText]      VARCHAR (50)  NULL,
    [TemplateIcon]      VARCHAR (256) NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         BIGINT        NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_HistoryTemplate_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         BIGINT        NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_HistoryTemplate_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DC_HistoryTemplate_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DC_HistoryTemplate_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__HistoryT__BB52E91AE0A9E4AC] PRIMARY KEY CLUSTERED ([HistoryTemplateId] ASC)
);

