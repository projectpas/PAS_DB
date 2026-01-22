CREATE TABLE [dbo].[VendorPayment] (
    [VendorPaymentId]      BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]             BIGINT        NOT NULL,
    [DefaultPaymentMethod] TINYINT       NOT NULL,
    [BankName]             VARCHAR (100) NULL,
    [BankAddressId]        BIGINT        NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [VendorPayment_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [VendorPayment_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [VendorPayment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [VendorPayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorPayment] PRIMARY KEY CLUSTERED ([VendorPaymentId] ASC),
    CONSTRAINT [FK_VendorPayment_Address] FOREIGN KEY ([BankAddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_VendorPayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorPayment_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_VendorPayment_VendorPaymentMethod] FOREIGN KEY ([DefaultPaymentMethod]) REFERENCES [dbo].[VendorPaymentMethod] ([VendorPaymentMethodId]),
    CONSTRAINT [FK_VendorPaymenttbl_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


CREATE TRIGGER [dbo].[Trg_VendorPaymentAudit]

   ON  [dbo].[VendorPayment]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorPaymentAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END