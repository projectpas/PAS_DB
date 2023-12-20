CREATE TABLE [dbo].[VendorPaymentMethod] (
    [VendorPaymentMethodId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description]           VARCHAR (250) NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [VPM_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [VPM_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [VendorPaymentMethod_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [VPM_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorPaymentMethod] PRIMARY KEY CLUSTERED ([VendorPaymentMethodId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_VendorPaymentMethodAudit]

   ON  [dbo].[VendorPaymentMethod]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorPaymentMethodAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END