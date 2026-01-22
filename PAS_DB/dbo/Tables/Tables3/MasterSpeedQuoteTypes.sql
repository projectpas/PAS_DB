CREATE TABLE [dbo].[MasterSpeedQuoteTypes] (
    [Id]              INT           IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)  NULL,
    [Description]     VARCHAR (250) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      CONSTRAINT [DF_MasterSpeedQuoteTypes_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    CONSTRAINT [PK_MasterSpeedQuoteTypes] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_MasterSpeedQuoteTypesAudit]

   ON  [dbo].[MasterSpeedQuoteTypes]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MasterSpeedQuoteTypesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END