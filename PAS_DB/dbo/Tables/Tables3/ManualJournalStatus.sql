CREATE TABLE [dbo].[ManualJournalStatus] (
    [ManualJournalStatusId] INT           IDENTITY (1, 1) NOT NULL,
    [Name]                  VARCHAR (100) NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManualJournalStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManualJournalStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_ManualJournalStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_ManualJournalStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManualJournalStatus] PRIMARY KEY CLUSTERED ([ManualJournalStatusId] ASC)
);

