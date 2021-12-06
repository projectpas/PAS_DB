CREATE TABLE [dbo].[ManagementSite] (
    [ManagementSiteId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [SiteId]                BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementSite_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [DF_ManagementSite_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF_ManagementSite_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF_ManagementSite_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ManagementSite] PRIMARY KEY CLUSTERED ([ManagementSiteId] ASC),
    CONSTRAINT [FK_ManagementSite_ManagementStructure] FOREIGN KEY ([ManagementStructureId]) REFERENCES [dbo].[ManagementStructure] ([ManagementStructureId]),
    CONSTRAINT [FK_ManagementSite_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ManagementSite_Site] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId])
);


GO




CREATE TRIGGER [dbo].[Trg_ManagementSiteAudit]

   ON  [dbo].[ManagementSite]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ManagementSiteAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END