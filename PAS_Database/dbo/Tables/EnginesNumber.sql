CREATE TABLE [dbo].[EnginesNumber] (
    [Id]              INT           NOT NULL,
    [Number]          BIGINT        NULL,
    [Memo]            VARCHAR (MAX) NULL,
    [MasterCompanyId] BIGINT        NULL,
    [IsActive]        BIT           CONSTRAINT [DF_EnginesNumber_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_EnginesNumber_IsDeleted] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC)
);

