CREATE TABLE [dbo].[AccountingIntegrationSetup] (
    [AccountingIntegrationSetupId] INT            IDENTITY (1, 1) NOT NULL,
    [IntegrationId]                INT            NOT NULL,
    [ClientId]                     VARCHAR (500)  NULL,
    [ClientSecret]                 VARCHAR (500)  NULL,
    [RedirectUrl]                  VARCHAR (5000) NULL,
    [Environment]                  VARCHAR (200)  NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NOT NULL,
    [UpdatedBy]                    VARCHAR (256)  NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  NOT NULL,
    [IsActive]                     BIT            NOT NULL,
    [IsDeleted]                    BIT            NOT NULL,
    [IsEnabled]                    BIT            NULL,
    [APIKey]                       VARCHAR (500)  NULL,
    CONSTRAINT [PK_AccountingIntegrationSetup] PRIMARY KEY CLUSTERED ([AccountingIntegrationSetupId] ASC)
);




GO
CREATE   TRIGGER [dbo].[Trg_AccountingIntegrationSetupAudit]
   ON  [dbo].[AccountingIntegrationSetup]
   AFTER INSERT,UPDATE
AS 
BEGIN

	INSERT INTO [dbo].[AccountingIntegrationSetupAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END