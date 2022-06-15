CREATE TABLE [dbo].[Publication] (
    [PublicationRecordId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [PublicationId]          VARCHAR (100) NOT NULL,
    [Description]            VARCHAR (256) NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) NOT NULL,
    [IsActive]               BIT           DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_Publication] PRIMARY KEY CLUSTERED ([PublicationRecordId] ASC),
    CONSTRAINT [FK_Publication_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_Publication_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Publication_PublicationType] FOREIGN KEY ([PublicationTypeId]) REFERENCES [dbo].[PublicationType] ([PublicationTypeId]),
    CONSTRAINT [FK_PublicationPublication_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_PublicationPublication_PublishedById] FOREIGN KEY ([PublishedById]) REFERENCES [dbo].[Module] ([ModuleId])
);




GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_PublicationAudit]

   ON  [dbo].[Publication]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO PublicationAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END