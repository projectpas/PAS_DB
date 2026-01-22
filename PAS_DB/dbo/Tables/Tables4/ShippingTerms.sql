CREATE TABLE [dbo].[ShippingTerms] (
    [ShippingTermsId] INT            IDENTITY (1, 1) NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [ShippingTerms_CT_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [ShippingTerms_CT_UD] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [IsActive]        BIT            CONSTRAINT [ShippingTerms_CT_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [ShippingTerms_CT_Delete] DEFAULT ((0)) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [SequenceNo]      INT            NULL,
    CONSTRAINT [PK_ShippingTerms] PRIMARY KEY CLUSTERED ([ShippingTermsId] ASC),
    CONSTRAINT [FK_ShippingTerms_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ShippingTerms] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO






Create TRIGGER [dbo].[Trg_ShippingTermsAudit]

   ON  [dbo].[ShippingTerms]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

INSERT INTO ShippingTermsAudit

SELECT ShippingTermsId,Description,MasterCompanyId,CreatedDate,UpdatedDate,CreatedBy,UpdatedBy,IsActive,IsDeleted,Name,Memo,SequenceNo FROM INSERTED

SET NOCOUNT ON;

END