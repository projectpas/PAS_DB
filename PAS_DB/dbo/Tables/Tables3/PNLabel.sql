CREATE TABLE [dbo].[PNLabel] (
    [PNLabelId]       BIGINT        IDENTITY (1, 1) NOT NULL,
    [Label]           VARCHAR (100) NOT NULL,
    [Value]           VARCHAR (100) NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_PNLabel_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_PNLabel_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF__PNLabel__IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF__PNLabel__IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_PNLabel] PRIMARY KEY CLUSTERED ([PNLabelId] ASC)
);

