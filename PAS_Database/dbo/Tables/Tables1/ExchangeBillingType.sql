CREATE TABLE [dbo].[ExchangeBillingType] (
    [ExchangeBillingTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]           VARCHAR (100)  NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ExchangeBillingType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_ExchangeBillingType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_ExchangeBillingType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_ExchangeBillingType_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchangeBillingType] PRIMARY KEY CLUSTERED ([ExchangeBillingTypeId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_ExchangeBillingTypeAudit]

   ON  [dbo].[ExchangeBillingType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExchangeBillingTypeAudit

	SELECT * FROM INSERTED

SET NOCOUNT ON;

END