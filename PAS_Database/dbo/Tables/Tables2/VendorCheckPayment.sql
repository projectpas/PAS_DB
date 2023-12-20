CREATE TABLE [dbo].[VendorCheckPayment] (
    [VendorCheckPaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]             BIGINT        NOT NULL,
    [CheckPaymentId]       BIGINT        NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) CONSTRAINT [VendorCheckPayment_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) CONSTRAINT [VendorCheckPayment_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT           CONSTRAINT [VendorCheckPayment_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT           CONSTRAINT [VendorCheckPayment_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorCheckPayment] PRIMARY KEY CLUSTERED ([VendorCheckPaymentId] ASC),
    CONSTRAINT [FK_VendorCheckPayment_CheckPayment] FOREIGN KEY ([CheckPaymentId]) REFERENCES [dbo].[CheckPayment] ([CheckPaymentId]),
    CONSTRAINT [FK_VendorCheckPayment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorCheckPayment_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);


GO


CREATE TRIGGER [dbo].[Trg_VendorCheckPaymentAudit]

   ON  [dbo].[VendorCheckPayment]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorCheckPaymentAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END