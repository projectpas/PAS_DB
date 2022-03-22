CREATE TABLE [dbo].[MasterCompanyAudit] (
    [MasterCompanyAuditId]     INT           IDENTITY (1, 1) NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [MasterCompanyCode]        VARCHAR (100) NULL,
    [CompanyName]              VARCHAR (500) NOT NULL,
    [TaxId]                    VARCHAR (15)  NULL,
    [EmailAddress]             VARCHAR (50)  NULL,
    [Address]                  VARCHAR (100) NULL,
    [CreatedBy]                VARCHAR (256) NULL,
    [UpdatedBy]                VARCHAR (256) NULL,
    [CreatedDate]              DATETIME2 (7) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) NOT NULL,
    [IsActive]                 BIT           NULL,
    [ManagementStructureLevel] INT           NULL,
    CONSTRAINT [PK_MasterCompanyAudit] PRIMARY KEY CLUSTERED ([MasterCompanyAuditId] ASC)
);



