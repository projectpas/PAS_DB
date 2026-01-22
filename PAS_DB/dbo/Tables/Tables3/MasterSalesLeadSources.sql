CREATE TABLE [dbo].[MasterSalesLeadSources] (
    [Id]              INT           NOT NULL,
    [Name]            VARCHAR (50)  NOT NULL,
    [Description]     VARCHAR (250) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      NULL,
    CONSTRAINT [PK_MasterSalesLeadSources] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_MasterSalesLeadSourcesAudit]

   ON  [dbo].[MasterSalesLeadSources]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MasterSalesLeadSourcesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END