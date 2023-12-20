CREATE TABLE [dbo].[IntegrationPortalAudit] (
    [IntegrationPortalAuditId] INT            IDENTITY (1, 1) NOT NULL,
    [IntegrationPortalId]      INT            NULL,
    [Description]              VARCHAR (256)  NOT NULL,
    [PortalURL]                VARCHAR (200)  NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  NOT NULL,
    [IsActive]                 BIT            NOT NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [IsDeleted]                BIT            NOT NULL
);

