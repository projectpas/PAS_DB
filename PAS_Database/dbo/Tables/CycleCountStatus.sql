CREATE TABLE [dbo].[CycleCountStatus] (
    [CycleCountStatusId] INT           IDENTITY (1, 1) NOT NULL,
    [Status]             VARCHAR (50)  NOT NULL,
    [Description]        VARCHAR (50)  NULL,
    [SequenceNo]         INT           NOT NULL,
    [MasterCompanyId]    INT           NOT NULL,
    [CreatedBy]          VARCHAR (256) NOT NULL,
    [UpdatedBy]          VARCHAR (256) NOT NULL,
    [CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_CycleCountStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7) CONSTRAINT [DF_CycleCountStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT           CONSTRAINT [DF_CycleCountStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT           CONSTRAINT [DF_CycleCountStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CycleCountStatus] PRIMARY KEY CLUSTERED ([CycleCountStatusId] ASC)
);

