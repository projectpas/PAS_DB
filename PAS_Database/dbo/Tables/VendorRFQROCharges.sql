﻿CREATE TABLE [dbo].[VendorRFQROCharges] (
    [VendorRFQROChargesId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRFQRepairOrderId]   BIGINT          NOT NULL,
    [VendorRFQROPartRecordId]  BIGINT          NULL,
    [ChargesTypeId]            BIGINT          NOT NULL,
    [VendorId]                 BIGINT          NULL,
    [Quantity]                 INT             NOT NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [Description]              VARCHAR (256)   NULL,
    [UnitCost]                 DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]             DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [BillingMethodId]          INT             NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [RefNum]                   VARCHAR (20)    NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_VendorRFQROCharges_CreatedDate_1] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_VendorRFQROCharges_UpdatedDate_1] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_VendorRFQROCharges_IsActive_1] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_VendorRFQROCharges_IsDeleted_1] DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_VendorRFQROCharges] PRIMARY KEY CLUSTERED ([VendorRFQROChargesId] ASC)
);




GO

CREATE   TRIGGER [dbo].[Trg_VendorRFQROChargesAudit]
ON  [dbo].[VendorRFQROCharges]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[VendorRFQROChargesAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END