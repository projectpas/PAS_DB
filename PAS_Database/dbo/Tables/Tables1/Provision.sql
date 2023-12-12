CREATE TABLE [dbo].[Provision] (
    [ProvisionId]     INT            IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Provision_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Provision_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Provision_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Provision_DC_Delete] DEFAULT ((0)) NOT NULL,
    [StatusCode]      VARCHAR (20)   NULL,
    CONSTRAINT [PK_Provision] PRIMARY KEY CLUSTERED ([ProvisionId] ASC),
    CONSTRAINT [Unique_Provision] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ProvisionAudit]

   ON  [dbo].[Provision]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ProvisionAudit

SELECT * FROM INSERTED

SET NOCOUNT ON;

END