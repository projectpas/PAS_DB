CREATE TABLE [dbo].[JournalType] (
    [ID]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [JournalTypeCode] VARCHAR (50)  NOT NULL,
    [JournalTypeName] VARCHAR (200) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [JournalType_DC_CDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [JournalType_DC_UDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [JournalType_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [JournalType_DC_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]      INT           NULL,
    [BatchType]       VARCHAR (20)  NULL,
    CONSTRAINT [PK_JournalType] PRIMARY KEY CLUSTERED ([ID] ASC)
);

