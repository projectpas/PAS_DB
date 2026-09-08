/*************************************************************           
 ** File:   [FleetQuoteAudit.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Audit history for Fleet Quote Header
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuoteAudit] (
    [AuditFleetQuoteId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [FleetQuoteId]              BIGINT          NOT NULL,
    [WorkOrderId]               BIGINT          NULL,
    [FleetQuoteNumber]          VARCHAR (100)   NULL,
    [OpenDate]                  DATETIME2 (7)   NOT NULL,
    [QuoteDueDate]              DATETIME2 (7)   NOT NULL,
    [ValidForDays]              INT             NULL,
    [ExpirationDate]            DATETIME2 (7)   NULL,
    [FleetQuoteStatusId]        BIGINT          NOT NULL,
    [CustomerId]                BIGINT          NOT NULL,
    [CurrencyId]                INT             NOT NULL,
    [DSO]                       VARCHAR (256)   NULL,
    [AccountsReceivableBalance] DECIMAL (18, 6) NULL,
    [SalesPersonId]             BIGINT          NULL,
    [EmployeeId]                BIGINT          NOT NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   NOT NULL,
    [IsActive]                  BIT             NOT NULL,
    [IsDeleted]                 BIT             NOT NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [Warnings]                  VARCHAR (256)   NULL,
    [SentDate]                  DATETIME2 (7)   NULL,
    [ApprovedDate]              DATETIME2 (7)   NULL,
    [VersionNo]                 VARCHAR (20)    NULL,
    [IsApprovalBypass]          BIT             NULL,
    [QuoteParentId]             BIGINT          NULL,
    [IsVersionIncrease]         BIT             NOT NULL,
    [Notes]                     NVARCHAR (MAX)  NULL,
    [CustomerName]              VARCHAR (200)   NULL,
    [CustomerContact]           VARCHAR (200)   NULL,
    [CustomerContactId]         BIGINT          NULL,
    [AircraftTailNumber]        VARCHAR (100)   NULL,
    [FleetName]                 VARCHAR (100)   NULL,
    [CreditLimit]               DECIMAL (18, 6) NULL,
    [CreditTerms]               VARCHAR (200)   NULL,
    [ReportCurrencyId]          INT             NULL,
    [ForeignExchangeRate]       DECIMAL (18, 6) NULL,
    [IsPrintCorrectiveAction]   BIT             NULL,
    [ShipToSiteId]              BIGINT          NULL,
    [ShipToSiteName]            VARCHAR (100)   NULL,
    [Line1]                     VARCHAR (50)    NULL,
    [Line2]                     VARCHAR (50)    NULL,
    [City]                      VARCHAR (50)    NULL,
    [StateOrProvince]           VARCHAR (50)    NULL,
    [PostalCode]                VARCHAR (50)    NULL,
    [CountryId]                 BIGINT          NULL,
    [ApprovalCode]              VARCHAR (200)   NULL,
    CONSTRAINT [PK_FleetQuoteAudit] PRIMARY KEY CLUSTERED ([AuditFleetQuoteId] ASC)
);
