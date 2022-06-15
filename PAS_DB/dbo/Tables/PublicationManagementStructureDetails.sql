CREATE TABLE [dbo].[PublicationManagementStructureDetails] (
    [MSDetailsId]         BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleID]            INT           NOT NULL,
    [ReferenceID]         BIGINT        NOT NULL,
    [EntityMSID]          BIGINT        NOT NULL,
    [Level1Id]            BIGINT        NULL,
    [Level1Name]          VARCHAR (500) NULL,
    [Level2Id]            BIGINT        NULL,
    [Level2Name]          VARCHAR (500) NULL,
    [Level3Id]            BIGINT        NULL,
    [Level3Name]          VARCHAR (500) NULL,
    [Level4Id]            BIGINT        NULL,
    [Level4Name]          VARCHAR (500) NULL,
    [Level5Id]            BIGINT        NULL,
    [Level5Name]          VARCHAR (500) NULL,
    [Level6Id]            BIGINT        NULL,
    [Level6Name]          VARCHAR (500) NULL,
    [Level7Id]            BIGINT        NULL,
    [Level7Name]          VARCHAR (500) NULL,
    [Level8Id]            BIGINT        NULL,
    [Level8Name]          VARCHAR (500) NULL,
    [Level9Id]            BIGINT        NULL,
    [Level9Name]          VARCHAR (500) NULL,
    [Level10Id]           BIGINT        NULL,
    [Level10Name]         VARCHAR (500) NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_PublicationManagementStructureDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_PublicationManagementStructureDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_PublicationManagementStructureDetails_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_PublicationManagementStructureDetails_IsDeleted] DEFAULT ((0)) NOT NULL,
    [LastMSLevel]         VARCHAR (200) NULL,
    [AllMSlevels]         VARCHAR (MAX) NULL,
    [PublicationRecordId] BIGINT        NULL,
    CONSTRAINT [PK_PublicationManagementStructureDetails] PRIMARY KEY CLUSTERED ([MSDetailsId] ASC)
);


GO
CREATE TRIGGER [dbo].[Trg_PublicationManagementStructureDetailsAudit]
   ON  [dbo].[PublicationManagementStructureDetails]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
INSERT INTO PublicationManagementStructureDetailsAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END