CREATE TABLE [dbo].[VendorRFQPOCharges] (
    [VendorRFQPOChargeId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRFQPurchaseOrderId] BIGINT          NOT NULL,
    [VendorRFQPOPartRecordId]  BIGINT          NULL,
    [ChargesTypeId]            BIGINT          NOT NULL,
    [VendorId]                 BIGINT          NULL,
    [Quantity]                 DECIMAL (18, 6) NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [Description]              VARCHAR (256)   NULL,
    [UnitCost]                 DECIMAL (18, 6) NULL,
    [ExtendedCost]             DECIMAL (18, 6) NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [MarkupFixedPrice]         DECIMAL (18, 6) NULL,
    [BillingMethodId]          INT             NULL,
    [BillingAmount]            DECIMAL (18, 6) NULL,
    [BillingRate]              DECIMAL (18, 6) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [RefNum]                   VARCHAR (20)    NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_VendorRFQPOCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_VendorRFQPOCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_VendorRFQPOCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_VendorRFQPOCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [VendorName]               VARCHAR (100)   NULL,
    [ChargeName]               VARCHAR (50)    NULL,
    [MarkupName]               VARCHAR (50)    NULL,
    [ItemMasterId]             BIGINT          NULL,
    [PartNumber]               VARCHAR (100)   NULL,
    [ConditionId]              BIGINT          NULL,
    [LineNum]                  INT             NULL,
    [ManufacturerId]           BIGINT          NULL,
    [Manufacturer]             VARCHAR (100)   NULL,
    [UOMId]                    BIGINT          NULL,
    CONSTRAINT [PK_VendorRFQPOCharges] PRIMARY KEY CLUSTERED ([VendorRFQPOChargeId] ASC),
    CONSTRAINT [FK_VendorRFQPOCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_VendorRFQPOCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO
CREATE   TRIGGER [dbo].[Trg_VendorRFQPOChargesAudit]
ON  [dbo].[VendorRFQPOCharges]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[VendorRFQPOChargesAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END