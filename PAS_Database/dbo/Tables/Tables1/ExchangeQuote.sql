CREATE TABLE [dbo].[ExchangeQuote] (
    [ExchangeQuoteId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [Type]                     INT             NOT NULL,
    [TypeName]                 VARCHAR (50)    NULL,
    [ExchangeQuoteNumber]      VARCHAR (50)    NOT NULL,
    [CustomerReference]        VARCHAR (100)   NULL,
    [OpenDate]                 DATETIME2 (7)   NULL,
    [QuoteExpireDate]          DATETIME2 (7)   NOT NULL,
    [Version]                  INT             NOT NULL,
    [VersionNumber]            VARCHAR (50)    NULL,
    [VersionDate]              DATETIME2 (7)   NULL,
    [PriorityId]               INT             NULL,
    [StatusId]                 INT             CONSTRAINT [DF_ExchangeQuote_StatusId] DEFAULT ((1)) NOT NULL,
    [StatusName]               VARCHAR (50)    NULL,
    [StatusChangeDate]         DATETIME2 (7)   CONSTRAINT [DF_ExchangeQuote_StatusChangeDate] DEFAULT (getdate()) NOT NULL,
    [CustomerId]               BIGINT          NOT NULL,
    [CustomerName]             VARCHAR (100)   NULL,
    [CustomerCode]             VARCHAR (50)    NULL,
    [CustomerContactId]        BIGINT          NOT NULL,
    [CreditLimit]              DECIMAL (18, 2) NULL,
    [CreditTermId]             INT             NULL,
    [CreditLimitName]          VARCHAR (50)    NULL,
    [CreditTermName]           VARCHAR (50)    NULL,
    [BalanceDue]               NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeQuote_BalanceDue] DEFAULT ((0)) NOT NULL,
    [SalesPersonId]            BIGINT          NULL,
    [SalesPersonName]          VARCHAR (50)    NULL,
    [ApprovedById]             BIGINT          NULL,
    [ApprovedByName]           VARCHAR (50)    NULL,
    [ApprovedDate]             DATETIME2 (7)   NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeQuote_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeQuote_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_ExchangeQuote_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_ExchangeQuote_IsActive] DEFAULT ((1)) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [ManagementStructureId]    BIGINT          NULL,
    [EmployeeId]               BIGINT          NULL,
    [IsApproved]               BIT             CONSTRAINT [DF_ExchangeQuote_IsApproved] DEFAULT ((0)) NULL,
    [CustomerContactName]      VARCHAR (200)   NULL,
    [CustomerContactEmail]     VARCHAR (100)   NULL,
    [ValidForDays]             INT             DEFAULT ((0)) NOT NULL,
    [CustomerSeviceRepId]      BIGINT          NULL,
    [CustomerServiceRepName]   VARCHAR (50)    NULL,
    [CustomerWarningId]        BIGINT          NULL,
    [CustomerWarningName]      VARCHAR (50)    NULL,
    [EmployeeName]             VARCHAR (50)    NULL,
    [ManagementStructureName1] VARCHAR (50)    NULL,
    [ManagementStructureName2] VARCHAR (50)    NULL,
    [ManagementStructureName3] VARCHAR (50)    NULL,
    [ManagementStructureName4] VARCHAR (50)    NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [Notes]                    NVARCHAR (MAX)  NULL,
    [AgentId]                  BIGINT          NULL,
    [AgentName]                VARCHAR (50)    NULL,
    [ManagementStructureName]  VARCHAR (50)    NULL,
    [AccountTypeId]            INT             NULL,
    [RestrictPMA]              BIT             DEFAULT ((0)) NOT NULL,
    [RestrictDER]              BIT             DEFAULT ((0)) NOT NULL,
    [ContractReference]        VARCHAR (100)   NULL,
    [EnforceEffectiveDate]     DATETIME2 (7)   NULL,
    [IsEnforceApproval]        BIT             NULL,
    [IsNewVersionCreated]      BIT             DEFAULT ((0)) NOT NULL,
    [QuoteParentId]            BIGINT          NULL,
    [IsFreightFlatRate]        BIT             NULL,
    [FreightFlatRate]          DECIMAL (18, 2) NULL,
    [IsChargeFlatRate]         BIT             NULL,
    [ChargeFlatRate]           DECIMAL (18, 2) NULL,
    [FunctionalCurrencyId]     INT             NULL,
    [ReportCurrencyId]         INT             NULL,
    [ForeignExchangeRate]      DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_ExchangeQuote] PRIMARY KEY CLUSTERED ([ExchangeQuoteId] ASC),
    CONSTRAINT [FK_ExchangeQuote_CreditTerms] FOREIGN KEY ([CreditTermId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_ExchangeQuote_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_ExchangeQuote_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeQuote_SalesPersonId] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeQuote_StatusId] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[ExchangeStatus] ([ExchangeStatusId])
);








GO


CREATE TRIGGER [dbo].[Trg_ExchangeQuoteAudit]

   ON  [dbo].[ExchangeQuote]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeQuoteAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END