CREATE TABLE [dbo].[TrainingName] (
    [TrainingNameId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256) NOT NULL,
    [Memo]            VARCHAR (MAX) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_TrainingName_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_TrainingName_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_TrainingName_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_TrainingName_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TrainingName] PRIMARY KEY CLUSTERED ([TrainingNameId] ASC)
);

