CREATE TABLE [dbo].[VendorInternationlWirePayment] (
    [VendorInternationalWirePaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]                         BIGINT        NOT NULL,
    [InternationalWirePaymentId]       BIGINT        NOT NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) CONSTRAINT [VendorInternationlWirePayment_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) CONSTRAINT [VendorInternationlWirePayment_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                         BIT           CONSTRAINT [VendorInternationlWirePayment_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT           CONSTRAINT [VendorInternationlWirePayment_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorInternationlWirePayment] PRIMARY KEY CLUSTERED ([VendorInternationalWirePaymentId] ASC),
    CONSTRAINT [FK_VendorInternationlWirePayment_InternationalWirePayment] FOREIGN KEY ([InternationalWirePaymentId]) REFERENCES [dbo].[InternationalWirePayment] ([InternationalWirePaymentId]),
    CONSTRAINT [FK_VendorInternationlWirePayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorInternationlWirePayment_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO






CREATE TRIGGER [dbo].[Trg_VendorInternationlWirePaymentAudit]

   ON  [dbo].[VendorInternationlWirePayment]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorInternationlWirePaymentAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END