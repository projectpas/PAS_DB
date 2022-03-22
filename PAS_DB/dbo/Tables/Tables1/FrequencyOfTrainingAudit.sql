CREATE TABLE [dbo].[FrequencyOfTrainingAudit] (
    [AuditFrequencyOfTrainingId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [FrequencyOfTrainingId]      BIGINT         NOT NULL,
    [FrequencyName]              VARCHAR (100)  NOT NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [CreatedDate]                DATETIME2 (7)  NULL,
    [CreatedBy]                  VARCHAR (256)  NULL,
    [UpdatedDate]                DATETIME2 (7)  NULL,
    [UpdatedBy]                  VARCHAR (256)  NULL,
    [IsActive]                   BIT            NOT NULL,
    [IsDeleted]                  BIT            NOT NULL,
    CONSTRAINT [PK_FrequencyOfTrainingAudit] PRIMARY KEY CLUSTERED ([AuditFrequencyOfTrainingId] ASC)
);

