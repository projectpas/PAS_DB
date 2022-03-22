CREATE TABLE [dbo].[CertificationTypeAudit] (
    [CertificationTypeAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CertificationTypeId]      BIGINT        NOT NULL,
    [CertificationName]        VARCHAR (256) NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedDate]              DATETIME      NOT NULL,
    [UpdatedDate]              DATETIME      NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [IsActive]                 BIT           NOT NULL,
    [IsDeleted]                BIT           NOT NULL,
    CONSTRAINT [PK__CertificationTypeAudit] PRIMARY KEY CLUSTERED ([CertificationTypeAuditId] ASC)
);

