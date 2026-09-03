CREATE TABLE [dbo].[LeaseStockline] (
    [LeaseStocklineId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseHeaderId]        BIGINT          NOT NULL,
    [ItemMasterId]         BIGINT          NOT NULL,
    [PN]                   NVARCHAR (100)  NULL,
    [PNDescription]        NVARCHAR (500)  NULL,
    [QtyOrder]             INT             NOT NULL,
    [QtyReserved]          INT             NOT NULL,
    [SN]                   NVARCHAR (100)  NULL,
    [StockLineId]          BIGINT          NOT NULL,
    [StocklineNumber]      VARCHAR (100)   NULL,
    [ConditionId]          BIGINT          NOT NULL,
    [OutrightPrice]        DECIMAL (18, 2) NULL,
    [FlatRate]             DECIMAL (18, 2) NULL,
    [PricingMethod]        NVARCHAR (100)  NULL,
    [BillingInterval]      NVARCHAR (100)  NULL,
    [MinimumCycles]        DECIMAL (18, 2) NULL,
    [MinimumTimes]         DECIMAL (18, 2) NULL,
    [MaximumCycles]        DECIMAL (18, 2) NULL,
    [MaximumTimes]         DECIMAL (18, 2) NULL,
    [UsagePerUnitCycles]   DECIMAL (18, 2) NULL,
    [UsagePerUnitTimes]    DECIMAL (18, 2) NULL,
    [OverrunPerUnitCycles] DECIMAL (18, 2) NULL,
    [OverrunPerUnitTimes]  DECIMAL (18, 2) NULL,
    [Maintenance]          DECIMAL (18, 2) NULL,
    [Insurance]            DECIMAL (18, 2) NULL,
    [Taxes]                DECIMAL (18, 2) NULL,
    [RateUnit]             NVARCHAR (50)   NULL,
    [BillingMethod]        NVARCHAR (50)   NULL,
    [MaintenancePer]       NVARCHAR (50)   NULL,
    [InsurancePer]         NVARCHAR (50)   NULL,
    [TaxesPer]             NVARCHAR (50)   NULL,
    [Notes]                NVARCHAR (MAX)  NULL,
    [StartDate]            DATETIME        NULL,
    [EndDate]              DATETIME        NULL,
    [ReservedBy]           VARCHAR (256)   NULL,
    [UnReservedBy]         VARCHAR (256)   NULL,
    [RepairOrderId]        BIGINT          NULL,
    [RONumber]             VARCHAR (100)   NULL,
    [WorkOrderId]          BIGINT          NULL,
    [WorkOrderNo]          VARCHAR (100)   NULL,
    [IsActive]             BIT             CONSTRAINT [DF_LeaseStockline_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT             CONSTRAINT [DF_LeaseStockline_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]      INT             NOT NULL,
    [CreatedBy]            VARCHAR (256)   NOT NULL,
    [CreatedDate]          DATETIME        CONSTRAINT [DF_LeaseStockline_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedBy]            VARCHAR (256)   NOT NULL,
    [UpdatedDate]          DATETIME        CONSTRAINT [DF_LeaseStockline_UpdatedDate] DEFAULT (getutcdate()) NULL,
    CONSTRAINT [PK_LeaseStockline] PRIMARY KEY CLUSTERED ([LeaseStocklineId] ASC),
    CONSTRAINT [FK_LeaseStockline_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);








GO
CREATE TRIGGER [dbo].[Trg_LeaseStocklineAudit]
   ON  [dbo].[LeaseStockline]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED)
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineAudit]
		SELECT * FROM INSERTED
	END

	-- Handles DELETE (rows exist only in DELETED)
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseStocklineAudit]
		SELECT * FROM DELETED
	END
END