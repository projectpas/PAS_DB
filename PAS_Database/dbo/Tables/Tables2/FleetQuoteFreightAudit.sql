/*************************************************************           
 ** File:   [FleetQuoteFreightAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Freight Charges
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteFreightAudit] (
    [AuditFleetQuoteFreightId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteFreightId]      BIGINT          NOT NULL,
    [FleetQuoteDetailsId]      BIGINT          NOT NULL,
    [ShipViaId]                BIGINT          NOT NULL,
    [Weight]                   VARCHAR (50)    NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [Amount]                   DECIMAL (20, 3) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   NOT NULL,
    [IsActive]                 BIT             NOT NULL,
    [IsDeleted]                BIT             NOT NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [MarkupFixedPrice]         VARCHAR (15)    NULL,
    [TaskId]                   BIGINT          NOT NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [Length]                   DECIMAL (10, 2) NULL,
    [Width]                    DECIMAL (10, 2) NULL,
    [Height]                   DECIMAL (10, 2) NULL,
    [UOMId]                    BIGINT          NULL,
    [DimensionUOMId]           BIGINT          NULL,
    [CurrencyId]               INT             NULL,
    [BillingMethodId]          INT             NULL,
    [TaskName]                 VARCHAR (100)   NULL,
    [Shipvia]                  VARCHAR (50)    NULL,
    [UomName]                  VARCHAR (50)    NULL,
    [DimensionUomName]         VARCHAR (50)    NULL,
    [Currency]                 VARCHAR (50)    NULL,
    [BillingName]              VARCHAR (50)    NULL,
    [MarkUp]                   VARCHAR (50)    NULL,
    CONSTRAINT [PK_FleetQuoteFreightAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteFreightId] ASC)
);
