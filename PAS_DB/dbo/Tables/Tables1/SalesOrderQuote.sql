CREATE TABLE [dbo].[SalesOrderQuote] (
    [SalesOrderQuoteId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [QuoteTypeId]              INT             NOT NULL,
    [OpenDate]                 DATETIME2 (7)   NULL,
    [ValidForDays]             INT             NOT NULL,
    [QuoteExpireDate]          DATETIME2 (7)   NOT NULL,
    [AccountTypeId]            INT             NOT NULL,
    [CustomerId]               BIGINT          NOT NULL,
    [CustomerContactId]        BIGINT          NULL,
    [CustomerReference]        VARCHAR (100)   NULL,
    [ContractReference]        VARCHAR (100)   NULL,
    [SalesPersonId]            BIGINT          NULL,
    [AgentName]                VARCHAR (50)    NULL,
    [CustomerSeviceRepId]      BIGINT          NULL,
    [ProbabilityId]            BIGINT          NULL,
    [LeadSourceId]             INT             NULL,
    [CreditLimit]              DECIMAL (18, 2) NULL,
    [CreditTermId]             INT             NULL,
    [EmployeeId]               BIGINT          NOT NULL,
    [RestrictPMA]              BIT             CONSTRAINT [SalesOrderQuote_RestrictPMA] DEFAULT ((0)) NOT NULL,
    [RestrictDER]              BIT             CONSTRAINT [SalesOrderQuote_RestrictDER] DEFAULT ((0)) NOT NULL,
    [ApprovedDate]             DATETIME2 (7)   NULL,
    [CurrencyId]               INT             NULL,
    [CustomerWarningId]        BIGINT          NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [Notes]                    NVARCHAR (MAX)  NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuote_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_SalesOrderQuote_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]                BIT             DEFAULT ((0)) NOT NULL,
    [StatusId]                 INT             DEFAULT ((1)) NOT NULL,
    [StatusChangeDate]         DATETIME2 (7)   DEFAULT (getdate()) NOT NULL,
    [ManagementStructureId]    BIGINT          NOT NULL,
    [Version]                  INT             NOT NULL,
    [AgentId]                  BIGINT          NULL,
    [QtyRequested]             INT             DEFAULT ((0)) NULL,
    [QtyToBeQuoted]            INT             DEFAULT ((0)) NULL,
    [SalesOrderQuoteNumber]    VARCHAR (50)    NOT NULL,
    [QuoteSentDate]            DATETIME2 (7)   NULL,
    [IsNewVersionCreated]      BIT             DEFAULT ((0)) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [SalesOrderQuote_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [QuoteParentId]            BIGINT          NULL,
    [QuoteTypeName]            VARCHAR (50)    NULL,
    [AccountTypeName]          VARCHAR (50)    NULL,
    [CustomerName]             VARCHAR (50)    NULL,
    [SalesPersonName]          VARCHAR (50)    NULL,
    [CustomerServiceRepName]   VARCHAR (50)    NULL,
    [ProbabilityName]          VARCHAR (50)    NULL,
    [LeadSourceName]           VARCHAR (50)    NULL,
    [CreditTermName]           VARCHAR (50)    NULL,
    [EmployeeName]             VARCHAR (50)    NULL,
    [CurrencyName]             VARCHAR (50)    NULL,
    [CustomerWarningName]      VARCHAR (50)    NULL,
    [ManagementStructureName]  VARCHAR (50)    NULL,
    [CustomerContactName]      VARCHAR (50)    NULL,
    [VersionNumber]            VARCHAR (50)    NULL,
    [CustomerCode]             VARCHAR (50)    NULL,
    [CustomerContactEmail]     VARCHAR (50)    NULL,
    [CreditLimitName]          VARCHAR (50)    NULL,
    [StatusName]               VARCHAR (50)    NULL,
    [ManagementStructureName1] VARCHAR (50)    NULL,
    [ManagementStructureName2] VARCHAR (50)    NULL,
    [ManagementStructureName3] VARCHAR (50)    NULL,
    [ManagementStructureName4] VARCHAR (50)    NULL,
    [EnforceEffectiveDate]     DATETIME2 (7)   NULL,
    [IsEnforceApproval]        BIT             NULL,
    [TotalFreight]             DECIMAL (20, 2) NULL,
    [TotalCharges]             DECIMAL (20, 2) NULL,
    [FreightBilingMethodId]    INT             NULL,
    [ChargesBilingMethodId]    INT             NULL,
    CONSTRAINT [PK_SalesOrderQuote] PRIMARY KEY CLUSTERED ([SalesOrderQuoteId] ASC),
    CONSTRAINT [FK_SalesOrderQuote_CreditTerms] FOREIGN KEY ([CreditTermId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_SalesOrderQuote_CurrencyId] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SalesOrderQuote_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_SalesOrderQuote_CustomerType] FOREIGN KEY ([AccountTypeId]) REFERENCES [dbo].[CustomerType] ([CustomerTypeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee_Agent] FOREIGN KEY ([AgentId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee_CustomerSeviceRep] FOREIGN KEY ([CustomerSeviceRepId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_Employee_SalesPerson] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuote_LeadSource] FOREIGN KEY ([LeadSourceId]) REFERENCES [dbo].[LeadSource] ([LeadSourceId]),
    CONSTRAINT [FK_SalesOrderQuote_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuote_MasterSalesOrderQuoteStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id]),
    CONSTRAINT [FK_SalesOrderQuote_MasterSalesOrderQuoteTypes] FOREIGN KEY ([QuoteTypeId]) REFERENCES [dbo].[MasterSalesOrderQuoteTypes] ([Id]),
    CONSTRAINT [FK_SalesOrderQuote_Percent] FOREIGN KEY ([ProbabilityId]) REFERENCES [dbo].[Percent] ([PercentId])
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderQuoteAudit]

   ON  [dbo].[SalesOrderQuote]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderQuoteAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END