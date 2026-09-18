CREATE TABLE [dbo].[LeaseCharges] (
    [LeaseChargesId]   BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseHeaderId]    BIGINT          NOT NULL,
    [LeaseStocklineId] BIGINT          NOT NULL,
    [ReportedDate]     DATETIME        NULL,
    [ChargesTypeId]    BIGINT          NOT NULL,
    [VendorId]         BIGINT          NULL,
    [Description]      VARCHAR (256)   NULL,
    [UOMId]            BIGINT          NULL,
    [Quantity]         DECIMAL (18, 6) NULL,
    [UnitCost]         DECIMAL (18, 6) NULL,
    [ExtendedCost]     DECIMAL (18, 6) NULL,
    [MasterCompanyId]  INT             NOT NULL,
    [CreatedBy]        VARCHAR (256)   NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME        CONSTRAINT [DF_LeaseCharges_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedDate]      DATETIME        CONSTRAINT [DF_LeaseCharges_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]         BIT             CONSTRAINT [DF_LeaseCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT             CONSTRAINT [DF_LeaseCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_LeaseCharges] PRIMARY KEY CLUSTERED ([LeaseChargesId] ASC),
    CONSTRAINT [FK_LeaseCharges_LeaseHeader] FOREIGN KEY ([LeaseHeaderId]) REFERENCES [dbo].[LeaseHeader] ([LeaseHeaderId]),
    CONSTRAINT [FK_LeaseCharges_LeaseStockline] FOREIGN KEY ([LeaseStocklineId]) REFERENCES [dbo].[LeaseStockline] ([LeaseStocklineId]),
    CONSTRAINT [FK_LeaseCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_LeaseCharges_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_LeaseCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO
CREATE TRIGGER [dbo].[Trg_LeaseChargesAudit]
   ON  [dbo].[LeaseCharges]
   AFTER INSERT, UPDATE, DELETE
AS
BEGIN
	SET NOCOUNT ON;

	-- Handles INSERT and UPDATE (rows exist in INSERTED)
	IF EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseChargesAudit]
		SELECT * FROM INSERTED
	END

	-- Handles DELETE (rows exist only in DELETED)
	IF EXISTS (SELECT 1 FROM DELETED) AND NOT EXISTS (SELECT 1 FROM INSERTED)
	BEGIN
		INSERT INTO [dbo].[LeaseChargesAudit]
		SELECT * FROM DELETED
	END
END
