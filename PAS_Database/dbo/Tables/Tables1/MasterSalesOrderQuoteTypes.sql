CREATE TABLE [dbo].[MasterSalesOrderQuoteTypes] (
    [Id]              INT           NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_MasterSalesOrderQuoteTypes] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO








CREATE TRIGGER [dbo].[Trg_MasterSalesOrderQuoteTypesAudit]

   ON  [dbo].[MasterSalesOrderQuoteTypes]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MasterSalesOrderQuoteTypesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END