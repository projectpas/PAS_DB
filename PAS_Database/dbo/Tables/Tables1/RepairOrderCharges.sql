CREATE TABLE [dbo].[RepairOrderCharges] (
    [RepairOrderChargesId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [RepairOrderId]            BIGINT          NOT NULL,
    [RepairOrderPartRecordId]  BIGINT          NULL,
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
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_RepairOrderCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_RepairOrderCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_RepairOrderCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_RepairOrderCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_RepairOrderCharges] PRIMARY KEY CLUSTERED ([RepairOrderChargesId] ASC)
);






GO
CREATE   TRIGGER [dbo].[Trg_RepairOrderChargesAudit]
ON  [dbo].[RepairOrderCharges]
   AFTER INSERT,DELETE,UPDATE
AS
BEGIN
	INSERT INTO [dbo].[RepairOrderChargesAudit]
	SELECT * FROM INSERTED
	SET NOCOUNT ON;
END