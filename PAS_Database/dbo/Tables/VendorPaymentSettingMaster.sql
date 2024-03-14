CREATE TABLE [dbo].[VendorPaymentSettingMaster] (
    [VendorPaymentSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [IsEnforceApproval]      BIT           CONSTRAINT [DF_VendorPaymentSettingMaster_IsEnforceApproval] DEFAULT ((0)) NOT NULL,
    [Effectivedate]          DATETIME2 (7) NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_VendorPaymentSettingMaster_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_VendorPaymentSettingMaster_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF_VendorPaymentSettingMaster_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_VendorPaymentSettingMaster_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorPaymentSettingMaster] PRIMARY KEY CLUSTERED ([VendorPaymentSettingId] ASC),
    CONSTRAINT [FK_VendorPaymentSettingMaster_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO

CREATE   TRIGGER [dbo].[Trg_VendorPaymentSettingMasterAudit]

   ON  [dbo].[VendorPaymentSettingMaster]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO VendorPaymentSettingMasterAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END