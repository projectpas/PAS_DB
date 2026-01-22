CREATE TABLE [dbo].[IntegrationPortal] (
    [IntegrationPortalId] INT            IDENTITY (1, 1) NOT NULL,
    [Description]         VARCHAR (256)  NOT NULL,
    [PortalURL]           VARCHAR (200)  NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [IntegrationPortal_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [IntegrationPortal_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT            CONSTRAINT [D_IntegrationPortal_Active] DEFAULT ((1)) NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [D_IntegrationPortal_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_IntegrationPortal] PRIMARY KEY CLUSTERED ([IntegrationPortalId] ASC),
    CONSTRAINT [FK_Integration_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [UQ_IntegrationPortal_codes] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO


-------------------

CREATE TRIGGER [dbo].[Trg_IntegrationAudit]

   ON  [dbo].[IntegrationPortal]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[IntegrationPortalAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END