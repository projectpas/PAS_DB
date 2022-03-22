CREATE TABLE [dbo].[ExchangeSalesOrder] (
    [ExchangeSalesOrderId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [Version]                  INT             CONSTRAINT [DF_ExchangeSalesOrder_Version] DEFAULT ((1)) NOT NULL,
    [TypeId]                   INT             NOT NULL,
    [OpenDate]                 DATETIME2 (7)   NOT NULL,
    [ShippedDate]              DATETIME2 (7)   NULL,
    [NumberOfItems]            INT             CONSTRAINT [DF_ExchangeSalesOrder_NumberOfItems] DEFAULT ((0)) NOT NULL,
    [AccountTypeId]            INT             NOT NULL,
    [CustomerId]               BIGINT          NOT NULL,
    [CustomerContactId]        BIGINT          NOT NULL,
    [CustomerReference]        VARCHAR (100)   NOT NULL,
    [CurrencyId]               INT             NULL,
    [TotalSalesAmount]         NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeSalesOrder_TotalSalesAmount] DEFAULT ((0)) NOT NULL,
    [CustomerHold]             NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeSalesOrder_CustomerHold] DEFAULT ((0)) NOT NULL,
    [DepositAmount]            NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeSalesOrder_DepositAmount] DEFAULT ((0)) NOT NULL,
    [BalanceDue]               NUMERIC (9, 2)  CONSTRAINT [DF_ExchangeSalesOrder_BalanceDue_1] DEFAULT ((0)) NOT NULL,
    [SalesPersonId]            BIGINT          NULL,
    [AgentId]                  BIGINT          NULL,
    [CustomerSeviceRepId]      BIGINT          NULL,
    [EmployeeId]               BIGINT          NOT NULL,
    [ApprovedById]             BIGINT          NULL,
    [ApprovedDate]             DATETIME2 (7)   NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [StatusId]                 INT             CONSTRAINT [DF_ExchangeSalesOrder_StatusId_1] DEFAULT ((1)) NOT NULL,
    [StatusChangeDate]         DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrder_StatusChangeDate_1] DEFAULT (getdate()) NOT NULL,
    [Notes]                    NVARCHAR (MAX)  NULL,
    [RestrictPMA]              BIT             CONSTRAINT [DF_ExchangeSalesOrder_RestrictPMA] DEFAULT ((0)) NOT NULL,
    [RestrictDER]              BIT             CONSTRAINT [DF_ExchangeSalesOrder_RestrictDER] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]    BIGINT          NOT NULL,
    [CustomerWarningId]        BIGINT          NULL,
    [CreatedBy]                VARCHAR (256)   NOT NULL,
    [CreatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrder_CreatedDate_1] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                VARCHAR (256)   NOT NULL,
    [UpdatedDate]              DATETIME2 (7)   CONSTRAINT [DF_ExchangeSalesOrder_UpdatedDate_1] DEFAULT (getdate()) NOT NULL,
    [MasterCompanyId]          INT             NOT NULL,
    [IsDeleted]                BIT             CONSTRAINT [DF_ExchangeSalesOrder_IsDeleted_1] DEFAULT ((0)) NOT NULL,
    [ExchangeQuoteId]          BIGINT          NULL,
    [QtyRequested]             INT             CONSTRAINT [DF_ExchangeSalesOrder_QtyRequested] DEFAULT ((0)) NULL,
    [QtyToBeQuoted]            INT             CONSTRAINT [DF_ExchangeSalesOrder_QtyToBeQuoted] DEFAULT ((0)) NULL,
    [ExchangeSalesOrderNumber] VARCHAR (50)    NOT NULL,
    [IsActive]                 BIT             CONSTRAINT [DF_ExchangeSalesOrder_IsActive_1] DEFAULT ((1)) NOT NULL,
    [ContractReference]        VARCHAR (100)   NULL,
    [TypeName]                 VARCHAR (50)    NULL,
    [AccountTypeName]          VARCHAR (256)   NULL,
    [CustomerName]             VARCHAR (100)   NULL,
    [CustomerCode]             VARCHAR (100)   NULL,
    [SalesPersonName]          VARCHAR (80)    NULL,
    [CustomerServiceRepName]   VARCHAR (80)    NULL,
    [EmployeeName]             VARCHAR (80)    NULL,
    [CurrencyName]             VARCHAR (50)    NULL,
    [CustomerWarningName]      VARCHAR (300)   NULL,
    [ManagementStructureName]  VARCHAR (286)   NULL,
    [CreditLimit]              DECIMAL (18, 2) NULL,
    [CreditTermId]             INT             NULL,
    [CreditLimitName]          VARCHAR (50)    NULL,
    [CreditTermName]           VARCHAR (50)    NULL,
    [VersionNumber]            VARCHAR (50)    NULL,
    [ExchangeQuoteNumber]      VARCHAR (50)    NULL,
    [IsApproved]               BIT             NULL,
    CONSTRAINT [PK_ExchangeSalesOrder_1] PRIMARY KEY CLUSTERED ([ExchangeSalesOrderId] ASC),
    CONSTRAINT [FK_ExchangeSalesOrder_Agent] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeSalesOrder_CreditTerm] FOREIGN KEY ([CreditTermId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_ExchangeSalesOrder_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ExchangeSalesOrder_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_ExchangeSalesOrder_CustomerSeviceRep] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeSalesOrder_CustomerType] FOREIGN KEY ([AccountTypeId]) REFERENCES [dbo].[CustomerType] ([CustomerTypeId]),
    CONSTRAINT [FK_ExchangeSalesOrder_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeSalesOrder_ExchangeQuote] FOREIGN KEY ([ExchangeQuoteId]) REFERENCES [dbo].[ExchangeQuote] ([ExchangeQuoteId]),
    CONSTRAINT [FK_ExchangeSalesOrder_ExchangeType] FOREIGN KEY ([TypeId]) REFERENCES [dbo].[ExchangeType] ([Id]),
    CONSTRAINT [FK_ExchangeSalesOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_ExchangeSalesOrder_SalesPerson] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_ExchangeSalesOrder_Status] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[ExchangeStatus] ([ExchangeStatusId])
);




GO


CREATE TRIGGER [dbo].[Trg_ExchangeSalesOrderAudit]

   ON  [dbo].[ExchangeSalesOrder]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO ExchangeSalesOrderAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;

END