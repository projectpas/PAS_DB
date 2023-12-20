CREATE TABLE [dbo].[ManualJournalType] (
    [ManualJournalTypeId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]                VARCHAR (100) NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_ManualJournalType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_ManualJournalType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_ManualJournalType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_ManualJournalType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManualJournalType] PRIMARY KEY CLUSTERED ([ManualJournalTypeId] ASC)
);

