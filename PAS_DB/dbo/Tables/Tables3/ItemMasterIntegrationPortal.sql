CREATE TABLE [dbo].[ItemMasterIntegrationPortal] (
    [ItemMasterIntegrationPortalId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]                  BIGINT        NOT NULL,
    [IntegrationPortalId]           INT           NOT NULL,
    [MasterCompanyId]               INT           NOT NULL,
    [CreatedBy]                     VARCHAR (256) NULL,
    [UpdatedBy]                     VARCHAR (256) NULL,
    [CreatedDate]                   DATETIME2 (7) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7) NOT NULL,
    [IsActive]                      BIT           NULL,
    [IsDeleted]                     BIT           CONSTRAINT [ItemMasterIntegrationPortal_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ItemMasterIntegrationPortal] PRIMARY KEY CLUSTERED ([ItemMasterIntegrationPortalId] ASC),
    CONSTRAINT [FK_ItemMasterIntegrationPortal_IntegrationPortal] FOREIGN KEY ([IntegrationPortalId]) REFERENCES [dbo].[IntegrationPortal] ([IntegrationPortalId]),
    CONSTRAINT [FK_ItemMasterIntegrationPortal_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_ItemMasterIntegrationPortal_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO








CREATE TRIGGER [dbo].[Trg_ItemMasterIntegrationPortalAudit]

   ON  [dbo].[ItemMasterIntegrationPortal]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO [dbo].[ItemMasterIntegrationPortalAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END