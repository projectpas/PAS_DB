CREATE TABLE [dbo].[TagTypeMappingAudit] (
    [TagTypeMappingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TagTypeMappingId]      BIGINT        NOT NULL,
    [ModuleId]              INT           NOT NULL,
    [TagTypeId]             BIGINT        NOT NULL,
    [ReferenceId]           BIGINT        NOT NULL,
    [AttachmentId]          BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) NOT NULL,
    [IsActive]              BIT           NOT NULL,
    [IsDeleted]             BIT           NOT NULL,
    CONSTRAINT [PK_TagTypeMappingAudit] PRIMARY KEY CLUSTERED ([TagTypeMappingAuditId] ASC)
);

