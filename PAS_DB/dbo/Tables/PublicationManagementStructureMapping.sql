CREATE TABLE [dbo].[PublicationManagementStructureMapping] (
    [PublicationManagementStructureMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PublicationRecordId]                     BIGINT        NOT NULL,
    [ManagementStructureId]                   BIGINT        NOT NULL,
    [MasterCompanyId]                         INT           NOT NULL,
    [CreatedBy]                               VARCHAR (256) NOT NULL,
    [UpdatedBy]                               VARCHAR (256) NOT NULL,
    [CreatedDate]                             DATETIME2 (7) NOT NULL,
    [UpdatedDate]                             DATETIME2 (7) NOT NULL,
    [IsActive]                                BIT           NOT NULL,
    [IsDeleted]                               BIT           NOT NULL,
    CONSTRAINT [PK_PublicationManagementStructureMapping] PRIMARY KEY CLUSTERED ([PublicationManagementStructureMappingId] ASC),
    CONSTRAINT [FK_PublicationManagementStructureMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

