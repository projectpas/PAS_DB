CREATE TABLE [dbo].[InvoiceType] (
    [InvoiceTypeId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_InvoiceType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_InvoiceType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_InvoiceType] PRIMARY KEY CLUSTERED ([InvoiceTypeId] ASC),
    CONSTRAINT [FK_InvoiceType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_InvoiceType] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_InvoiceTypeAudit]

   ON  [dbo].[InvoiceType]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	

	INSERT INTO InvoiceTypeAudit

	SELECT * FROM INSERTED



SET NOCOUNT ON;

END