CREATE TABLE [dbo].[LegalEntityTagNameMappingAudit] (
    [TagNameMappingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TagNameMappingId]      BIGINT        NOT NULL,
    [TagName]               VARCHAR (256) NOT NULL,
    [LegalEntityId]         BIGINT        NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    [MasterCompanyId]       INT           NULL,
    CONSTRAINT [PK_LegalEntityTagNameMappingAudit] PRIMARY KEY CLUSTERED ([TagNameMappingAuditId] ASC)
);

