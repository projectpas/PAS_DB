CREATE TABLE [dbo].[ShippingReference] (
    [ShippingReferenceId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                NVARCHAR (200) NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NULL,
    [CreatedBy]           VARCHAR (1)    NULL,
    [UpdatedBy]           VARCHAR (1)    NULL,
    [CreatedDate]         DATETIME2 (7)  NULL,
    [UpdatedDate]         DATETIME2 (7)  NULL,
    [IsActive]            BIT            NULL,
    [IsDeleted]           BIT            NULL,
    PRIMARY KEY CLUSTERED ([ShippingReferenceId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ShippingReferenceAudit]

   ON  [dbo].[ShippingReference]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ShippingReferenceAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END