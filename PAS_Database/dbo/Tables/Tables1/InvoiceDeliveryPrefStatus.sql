CREATE TABLE [dbo].[InvoiceDeliveryPrefStatus] (
    [InvDelPrefStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Status]             NVARCHAR (100) NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_InvoiceDeliveryPrefStatus_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_InvoiceDeliveryPrefStatus_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_InvoiceDeliveryPrefStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_InvoiceDeliveryPrefStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNo]         INT            NULL,
    CONSTRAINT [PK_InvoiceDeliveryPrefStatus] PRIMARY KEY CLUSTERED ([InvDelPrefStatusId] ASC)
);


GO




CREATE TRIGGER [dbo].[TrgInvoiceDeliveryPrefStatusAudit]
   ON  [dbo].[InvoiceDeliveryPrefStatus]
AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO InvoiceDeliveryPrefStatusAudit
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END