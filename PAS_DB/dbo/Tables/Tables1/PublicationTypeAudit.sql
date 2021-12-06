CREATE TABLE [dbo].[PublicationTypeAudit] (
    [PublicationTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PublicationTypeId]      BIGINT         NOT NULL,
    [Name]                   VARCHAR (256)  NOT NULL,
    [Description]            VARCHAR (256)  NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (50)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)  NOT NULL,
    [UpdatedBy]              VARCHAR (50)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  NOT NULL,
    [IsActive]               BIT            NOT NULL,
    [IsDeleted]              BIT            NOT NULL,
    PRIMARY KEY CLUSTERED ([PublicationTypeAuditId] ASC)
);

