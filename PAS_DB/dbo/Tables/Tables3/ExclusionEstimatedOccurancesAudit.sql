CREATE TABLE [dbo].[ExclusionEstimatedOccurancesAudit] (
    [ExclusionEstimatedOccurancesAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [Id]                                  INT           NOT NULL,
    [CreatedBy]                           VARCHAR (50)  NULL,
    [CreatedDate]                         DATETIME      NOT NULL,
    [UpdatedBy]                           VARCHAR (50)  NULL,
    [UpdatedDate]                         DATETIME      NULL,
    [IsDeleted]                           BIT           NULL,
    [Name]                                VARCHAR (256) NULL,
    CONSTRAINT [PK_ExclusionEstimatedOccurancesAudit] PRIMARY KEY CLUSTERED ([ExclusionEstimatedOccurancesAuditId] ASC)
);

