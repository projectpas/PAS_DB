CREATE TABLE [dbo].[MasterSalesProbablity] (
    [Id]              INT           NOT NULL,
    [Value]           INT           NOT NULL,
    [Description]     VARCHAR (250) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (50)  NOT NULL,
    [CreatedDate]     DATETIME      DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (50)  NULL,
    [UpdatedDate]     DATETIME      NULL,
    CONSTRAINT [PK_MasterSalesProbablity] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_MasterSalesProbablityAudit]

   ON  [dbo].[MasterSalesProbablity]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MasterSalesProbablityAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END