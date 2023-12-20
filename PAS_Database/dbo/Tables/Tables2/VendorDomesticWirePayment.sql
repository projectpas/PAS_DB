CREATE TABLE [dbo].[VendorDomesticWirePayment] (
    [VendorDomesticWirePaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]                    BIGINT        NOT NULL,
    [DomesticWirePaymentId]       BIGINT        NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [VendorDomesticWirePayment_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [VendorDomesticWirePayment_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [VendorDomesticWirePayment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [VendorDomesticWirePayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorDomesticWirePayment] PRIMARY KEY CLUSTERED ([VendorDomesticWirePaymentId] ASC),
    CONSTRAINT [FK_VendorDomesticWirePayment_DomesticWirePayment] FOREIGN KEY ([DomesticWirePaymentId]) REFERENCES [dbo].[DomesticWirePayment] ([DomesticWirePaymentId]),
    CONSTRAINT [FK_VendorDomesticWirePayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorDomesticWirePayment_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO


CREATE TRIGGER [dbo].[Trg_VendorDomesticWirePaymentAudit]

   ON  [dbo].[VendorDomesticWirePayment]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorDomesticWirePaymentAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END