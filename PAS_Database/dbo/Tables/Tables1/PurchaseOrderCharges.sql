CREATE TABLE [dbo].[PurchaseOrderCharges] (
    [PurchaseOrderChargestId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId]           BIGINT          NOT NULL,
    [PurchaseOrderPartRecordId] BIGINT          NULL,
    [ChargesTypeId]             BIGINT          NOT NULL,
    [VendorId]                  BIGINT          NULL,
    [Quantity]                  INT             NOT NULL,
    [MarkupPercentageId]        BIGINT          NULL,
    [Description]               VARCHAR (256)   NULL,
    [UnitCost]                  DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]              DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [MarkupFixedPrice]          DECIMAL (20, 2) NULL,
    [BillingMethodId]           INT             NULL,
    [BillingAmount]             DECIMAL (20, 2) NULL,
    [BillingRate]               DECIMAL (20, 2) NULL,
    [HeaderMarkupId]            BIGINT          NULL,
    [RefNum]                    VARCHAR (20)    NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_PurchaseOrderCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_PurchaseOrderCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_PurchaseOrderCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_PurchaseOrderCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    [HeaderMarkupPercentageId]  BIGINT          NULL,
    [VendorName]                VARCHAR (100)   NULL,
    [ChargeName]                VARCHAR (50)    NULL,
    [MarkupName]                VARCHAR (50)    NULL,
    [ItemMasterId]              BIGINT          NULL,
    [PartNumber]                VARCHAR (100)   NULL,
    [ConditionId]               BIGINT          NULL,
    [LineNum]                   INT             NULL,
    [ManufacturerId]            BIGINT          NULL,
    [Manufacturer]              VARCHAR (100)   NULL,
    [UOMId]                     BIGINT          NULL,
    CONSTRAINT [PK_PurchaseOrderCharges] PRIMARY KEY CLUSTERED ([PurchaseOrderChargestId] ASC),
    CONSTRAINT [FK_PurchaseOrderCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_PurchaseOrderCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO


CREATE TRIGGER [dbo].[Trg_PurchaseOrderChargesAudit]
ON  [dbo].[PurchaseOrderCharges]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[PurchaseOrderChargesAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END