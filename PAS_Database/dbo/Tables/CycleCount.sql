CREATE TABLE [dbo].[CycleCount] (
    [CycleCountId]          BIGINT        IDENTITY (1, 1) NOT NULL,
    [CycleCountNumber]      VARCHAR (50)  NOT NULL,
    [EntryDate]             DATETIME2 (7) NOT NULL,
    [EntryTime]             TIME (7)      NOT NULL,
    [StatusId]              INT           NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [IsEnforce]             BIT           NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_CycleCount_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_CycleCount_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_CycleCount_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_CycleCount_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CycleCount] PRIMARY KEY CLUSTERED ([CycleCountId] ASC),
    CONSTRAINT [FK_CycleCount_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

