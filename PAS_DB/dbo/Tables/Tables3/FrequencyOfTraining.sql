CREATE TABLE [dbo].[FrequencyOfTraining] (
    [FrequencyOfTrainingId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FrequencyName]         VARCHAR (100)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NULL,
    [CreatedBy]             VARCHAR (256)  NULL,
    [UpdatedDate]           DATETIME2 (7)  NULL,
    [UpdatedBy]             VARCHAR (256)  NULL,
    [IsActive]              BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_FrequencyOfTraining] PRIMARY KEY CLUSTERED ([FrequencyOfTrainingId] ASC)
);

