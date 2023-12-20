CREATE TABLE [dbo].[ChargesCurrencies] (
    [Id]          INT          IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50) CONSTRAINT [DF__ChargesCu__Creat__5299FF31] DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME     CONSTRAINT [DF_ChargesCurrencies_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]   VARCHAR (50) CONSTRAINT [DF__ChargesCu__Updat__538E236A] DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME     CONSTRAINT [DF__ChargesCu__Updat__548247A3] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]   BIT          CONSTRAINT [DF__ChargesCu__IsDel__55766BDC] DEFAULT ((0)) NOT NULL,
    [Name]        VARCHAR (50) CONSTRAINT [DF__ChargesCur__Name__566A9015] DEFAULT (NULL) NULL,
    [Symbol]      VARCHAR (10) CONSTRAINT [DF__ChargesCu__Symbo__575EB44E] DEFAULT (NULL) NULL,
    CONSTRAINT [PK__ChargesC__3214EC0791A7D5F0] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ChargesCurrenciesAudit]

   ON  [dbo].[ChargesCurrencies]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ChargesCurrenciesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END