CREATE TABLE [dbo].[PublicationAudit] (
    [PublicationAuditId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [PublicationRecordId]    BIGINT        NOT NULL,
    [PublicationId]          VARCHAR (100) NOT NULL,
    [Description]            VARCHAR (256) NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) NOT NULL,
    [IsActive]               BIT           NOT NULL,
    [IsDeleted]              BIT           NOT NULL,
    [EntryDate]              DATETIME2 (7) NULL,
    [ASD]                    VARCHAR (100) NULL,
    [revisionDate]           DATETIME2 (7) NULL,
    [VerifiedDate]           DATETIME2 (7) NULL,
    [NextReviewDate]         DATETIME2 (7) NULL,
    [PublicationTypeId]      BIGINT        NOT NULL,
    [EmployeeId]             BIGINT        NULL,
    [ExpirationDate]         DATETIME      NULL,
    [Sequence]               INT           NULL,
    [RevisionNum]            VARCHAR (100) NULL,
    [VerifiedBy]             BIGINT        NULL,
    [VerifiedStatus]         BIT           NOT NULL,
    [LocationId]             BIGINT        NOT NULL,
    [PublishedById]          INT           NULL,
    [PublishedByRefId]       BIGINT        NULL,
    [PublishedByOthers]      VARCHAR (100) NULL,
    [ManagementStructureIds] VARCHAR (50)  NULL,
    CONSTRAINT [PK_PublicationAudit] PRIMARY KEY CLUSTERED ([PublicationAuditId] ASC)
);



