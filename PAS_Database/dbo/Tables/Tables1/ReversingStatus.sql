CREATE TABLE [dbo].[ReversingStatus] (
    [ReversingStatusId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]              VARCHAR (100) NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_ReversingStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_ReversingStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DF_ReversingStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF_ReversingStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ReversingStatus] PRIMARY KEY CLUSTERED ([ReversingStatusId] ASC)
);

