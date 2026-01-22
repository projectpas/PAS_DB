CREATE TABLE [dbo].[JournalTypeSetting] (
    [ID]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [JournalTypeID]   BIGINT        NOT NULL,
    [IsEnforcePrint]  BIT           NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [JournalTypeSetting_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [JournalTypeSetting_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [JournalTypeSetting_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [JournalTypeSetting_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsAppendtoBatch] BIT           NULL,
    [IsAutoPost]      BIT           NULL,
    CONSTRAINT [PK_JournalTypeSetting] PRIMARY KEY CLUSTERED ([ID] ASC)
);

