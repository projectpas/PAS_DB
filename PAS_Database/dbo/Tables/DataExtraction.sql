CREATE TABLE [dbo].[DataExtraction] (
    [Id]              BIGINT        IDENTITY (1, 1) NOT NULL,
    [Field]           VARCHAR (200) NULL,
    [Question]        VARCHAR (MAX) NULL,
    [Type]            VARCHAR (100) NULL,
    [MasterCompanyId] INT           NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_DataExtraction_CreatedDate_1] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_DataExtraction_UpdatedDate_1] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_DataExtraction_IsDeleted_1] DEFAULT ((0)) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_DataExtraction_IsActive_1] DEFAULT ((1)) NOT NULL,
    CONSTRAINT [PK_DataExtraction] PRIMARY KEY CLUSTERED ([Id] ASC)
);

