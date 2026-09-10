/*************************************************************           
 ** File:   [FleetQuote.sql]           
 ** Author:   SUMIT KUMAR
 ** Description: This Table is used to store Fleet Quote Header Information
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description
 ** --   --------     -------			--------------------------------
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
    2    09/10/2026   Kishor Makwana	Added FK_FleetQuote_FleetQuoteStatus -> dbo.FleetQuoteStatus [PN-17698]
 **************************************************************/
CREATE TABLE [dbo].[FleetQuote] (
    [FleetQuoteId]              BIGINT          IDENTITY (1, 1) NOT NULL,
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
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_FleetQuote_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_FleetQuote_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_FleetQuote_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_FleetQuote_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [Warnings]                  VARCHAR (256)   NULL,
    [SentDate]                  DATETIME2 (7)   NULL,
    [ApprovedDate]              DATETIME2 (7)   NULL,
    [VersionNo]                 VARCHAR (20)    NULL,
    [IsApprovalBypass]          BIT             CONSTRAINT [DF_FleetQuote_IsApprovalBypass] DEFAULT ((0)) NULL,
    [QuoteParentId]             BIGINT          NULL,
    [IsVersionIncrease]         BIT             CONSTRAINT [DF_FleetQuote_IsVersionIncrease] DEFAULT ((0)) NOT NULL,
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
    CONSTRAINT [PK_FleetQuote] PRIMARY KEY CLUSTERED ([FleetQuoteId] ASC),
    CONSTRAINT [FK_FleetQuote_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_FleetQuote_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_FleetQuote_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_FleetQuote_FleetQuoteStatus] FOREIGN KEY ([FleetQuoteStatusId]) REFERENCES [dbo].[FleetQuoteStatus] ([FleetQuoteStatusId]),
    CONSTRAINT [FK_FleetQuote_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_FleetQuote_QuoteParentId] FOREIGN KEY ([QuoteParentId]) REFERENCES [dbo].[FleetQuote] ([FleetQuoteId]),
    CONSTRAINT [FK_FleetQuote_SalesPerson] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_FleetQuote_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId])
);

GO

/*************************************************************           
 ** File:   [Trg_FleetQuoteAudit]           
 ** Author:   SUMIT KUMAR
 ** Description: This Trigger is used to insert data into FleetQuoteAudit
 ** Date:   09/08/2026        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    09/08/2026   SUMIT KUMAR		Created [PN-17706]
 **************************************************************/
CREATE TRIGGER [dbo].[Trg_FleetQuoteAudit]
   ON [dbo].[FleetQuote]
   AFTER INSERT, UPDATE
AS
BEGIN
    INSERT INTO [dbo].[FleetQuoteAudit]
    SELECT * FROM INSERTED;
    SET NOCOUNT ON;
END;
