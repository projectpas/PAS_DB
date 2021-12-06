CREATE TABLE [dbo].[MasterSpeedQuoteTypesAudit] (
    [MasterSpeedQuoteTypesAuditId] INT           IDENTITY (1, 1) NOT NULL,
    [Id]                           INT           NOT NULL,
    [Name]                         VARCHAR (50)  NULL,
    [Description]                  VARCHAR (250) NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (50)  NOT NULL,
    [CreatedDate]                  DATETIME      NOT NULL,
    [UpdatedBy]                    VARCHAR (50)  NULL,
    [UpdatedDate]                  DATETIME      NULL,
    [IsActive]                     BIT           NOT NULL,
    [IsDeleted]                    BIT           NOT NULL,
    CONSTRAINT [PK_MasterSpeedQuoteTypesAudit] PRIMARY KEY CLUSTERED ([MasterSpeedQuoteTypesAuditId] ASC)
);

