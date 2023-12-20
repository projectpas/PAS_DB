CREATE TABLE [dbo].[PaymentType] (
    [PaymentTypeId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description]   VARCHAR (50)  NOT NULL,
    [Comments]      VARCHAR (100) NULL,
    CONSTRAINT [PK_PaymentType] PRIMARY KEY CLUSTERED ([PaymentTypeId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_PaymentTypeAudit]

   ON  [dbo].[PaymentType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO PaymentTypeAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END