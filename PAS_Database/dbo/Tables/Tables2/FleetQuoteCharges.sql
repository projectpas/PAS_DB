/*************************************************************           
 ** File:   [FleetQuoteCharges.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Extra Charges
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteCharges] (
    [FleetQuoteChargesId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteDetailsId] BIGINT          NOT NULL,
    [ChargesTypeId]           BIGINT          NOT NULL,
    [VendorId]                BIGINT          NULL,
    [Quantity]                DECIMAL (18, 6) NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [Description]             VARCHAR (256)   NULL,
    [UnitCost]                DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]            DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteCharges_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_FleetQuoteCharges_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_FleetQuoteCharges_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_FleetQuoteCharges_IsDeleted] DEFAULT ((0)) NOT NULL,
    [TaskId]                  BIGINT          NOT NULL,
    [MarkupFixedPrice]        VARCHAR (15)    NULL,
    [BillingAmount]           DECIMAL (20, 2) NULL,
    [BillingRate]             DECIMAL (20, 2) NULL,
    [HeaderMarkupId]          BIGINT          NULL,
    [RefNum]                  VARCHAR (20)    NULL,
    [BillingMethodId]         INT             NULL,
    [TaskName]                VARCHAR (100)   NULL,
    [ChargeType]              VARCHAR (50)    NULL,
    [GlAccountName]           VARCHAR (50)    NULL,
    [VendorName]              VARCHAR (50)    NULL,
    [BillingName]             VARCHAR (50)    NULL,
    [MarkUp]                  VARCHAR (50)    NULL,
    [UOMId]                   BIGINT          NULL,
    CONSTRAINT [PK_FleetQuoteCharges] PRIMARY KEY CLUSTERED ([FleetQuoteChargesId] ASC),
    CONSTRAINT [FK_FleetQuoteCharges_Charge] FOREIGN KEY ([ChargesTypeId]) REFERENCES [dbo].[Charge] ([ChargeId]),
    CONSTRAINT [FK_FleetQuoteCharges_MarkupPercentage] FOREIGN KEY ([MarkupPercentageId]) REFERENCES [dbo].[Percent] ([PercentId]),
    CONSTRAINT [FK_FleetQuoteCharges_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuoteCharges_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_FleetQuoteCharges_FleetQuoteDetails] FOREIGN KEY ([FleetQuoteDetailsId]) REFERENCES [dbo].[FleetQuoteDetails] ([FleetQuoteDetailsId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteChargesAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteChargesAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteChargesAudit]
   ON [dbo].[FleetQuoteCharges]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteChargesAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
