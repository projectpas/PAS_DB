CREATE TABLE [dbo].[ShippingAccount] (
    [ShippingAccountId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [AccountNumber]     VARCHAR (200)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NULL,
    [CreatedBy]         VARCHAR (1)    NULL,
    [UpdatedBy]         VARCHAR (1)    NULL,
    [CreatedDate]       DATETIME2 (7)  NULL,
    [UpdatedDate]       DATETIME2 (7)  NULL,
    [IsActive]          BIT            NULL,
    [IsDeleted]         BIT            NULL,
    PRIMARY KEY CLUSTERED ([ShippingAccountId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ShippingAccountAudit]

   ON  [dbo].[ShippingAccount]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ShippingAccountAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END