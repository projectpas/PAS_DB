/*************************************************************           
 ** File:   [FleetQuoteChargesAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Extra Charges
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteChargesAudit] (
    [AuditFleetQuoteChargesId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteChargesId]      BIGINT          NOT NULL,
    [FleetQuoteDetailsId]      BIGINT          NOT NULL,
    [ChargesTypeId]            BIGINT          NOT NULL,
    [VendorId]                 BIGINT          NULL,
    [Quantity]                 DECIMAL (18, 6) NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [Description]              VARCHAR (256)   NULL,
    [UnitCost]                 DECIMAL (20, 2) NOT NULL,
    [ExtendedCost]             DECIMAL (20, 2) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NOT NULL,
    [IsActive]                 BIT             NOT NULL,
    [IsDeleted]                BIT             NOT NULL,
    [TaskId]                   BIGINT          NOT NULL,
    [MarkupFixedPrice]         VARCHAR (15)    NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [RefNum]                   VARCHAR (20)    NULL,
    [BillingMethodId]          INT             NULL,
    [TaskName]                 VARCHAR (100)   NULL,
    [ChargeType]               VARCHAR (50)    NULL,
    [GlAccountName]            VARCHAR (50)    NULL,
    [VendorName]               VARCHAR (50)    NULL,
    [BillingName]              VARCHAR (50)    NULL,
    [MarkUp]                   VARCHAR (50)    NULL,
    [UOMId]                    BIGINT          NULL,
    CONSTRAINT [PK_FleetQuoteChargesAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteChargesId] ASC)
);
