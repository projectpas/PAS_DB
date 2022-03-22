CREATE TABLE [dbo].[SalesOrder] (
    [SalesOrderId]            BIGINT          IDENTITY (1, 1) NOT NULL,
    [Version]                 INT             CONSTRAINT [DF__SalesOrde__Versi__05113BBC] DEFAULT ((1)) NOT NULL,
    [TypeId]                  INT             NOT NULL,
    [OpenDate]                DATETIME2 (7)   NOT NULL,
    [ShippedDate]             DATETIME2 (7)   NULL,
    [NumberOfItems]           INT             CONSTRAINT [DF__SalesOrde__Numbe__06055FF5] DEFAULT ((0)) NOT NULL,
    [AccountTypeId]           INT             NOT NULL,
    [CustomerId]              BIGINT          NOT NULL,
    [CustomerContactId]       BIGINT          NOT NULL,
    [CustomerReference]       VARCHAR (100)   NOT NULL,
    [CurrencyId]              INT             NULL,
    [TotalSalesAmount]        NUMERIC (9, 2)  CONSTRAINT [DF__SalesOrde__Total__06F9842E] DEFAULT ((0)) NOT NULL,
    [CustomerHold]            NUMERIC (9, 2)  CONSTRAINT [DF__SalesOrde__Custo__07EDA867] DEFAULT ((0)) NOT NULL,
    [DepositAmount]           NUMERIC (9, 2)  CONSTRAINT [DF__SalesOrde__Depos__08E1CCA0] DEFAULT ((0)) NOT NULL,
    [BalanceDue]              NUMERIC (9, 2)  CONSTRAINT [DF__SalesOrde__Balan__09D5F0D9] DEFAULT ((0)) NOT NULL,
    [SalesPersonId]           BIGINT          NULL,
    [AgentId]                 BIGINT          NULL,
    [CustomerSeviceRepId]     BIGINT          NULL,
    [EmployeeId]              BIGINT          NOT NULL,
    [ApprovedById]            BIGINT          NULL,
    [ApprovedDate]            DATETIME2 (7)   NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [StatusId]                INT             CONSTRAINT [DF__SalesOrde__Statu__0ACA1512] DEFAULT ((1)) NOT NULL,
    [StatusChangeDate]        DATETIME2 (7)   CONSTRAINT [DF__SalesOrde__Statu__0BBE394B] DEFAULT (getdate()) NOT NULL,
    [Notes]                   NVARCHAR (MAX)  NULL,
    [RestrictPMA]             BIT             CONSTRAINT [SalesOrder_RestrictPMA] DEFAULT ((0)) NOT NULL,
    [RestrictDER]             BIT             CONSTRAINT [SalesOrder_RestrictDER] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]   BIGINT          NOT NULL,
    [CustomerWarningId]       BIGINT          NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SalesOrder_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_SalesOrder_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF__SalesOrde__IsDel__0CB25D84] DEFAULT ((0)) NOT NULL,
    [SalesOrderQuoteId]       BIGINT          NULL,
    [QtyRequested]            INT             CONSTRAINT [DF__SalesOrde__QtyRe__70C02A4C] DEFAULT ((0)) NULL,
    [QtyToBeQuoted]           INT             CONSTRAINT [DF__SalesOrde__QtyTo__767903A2] DEFAULT ((0)) NULL,
    [SalesOrderNumber]        VARCHAR (50)    NOT NULL,
    [IsActive]                BIT             CONSTRAINT [SalesOrder_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [ContractReference]       VARCHAR (100)   NULL,
    [TypeName]                VARCHAR (50)    NULL,
    [AccountTypeName]         VARCHAR (256)   NULL,
    [CustomerName]            VARCHAR (100)   NULL,
    [SalesPersonName]         VARCHAR (80)    NULL,
    [CustomerServiceRepName]  VARCHAR (80)    NULL,
    [EmployeeName]            VARCHAR (80)    NULL,
    [CurrencyName]            VARCHAR (50)    NULL,
    [CustomerWarningName]     VARCHAR (300)   NULL,
    [ManagementStructureName] VARCHAR (286)   NULL,
    [CreditLimit]             DECIMAL (18, 2) NULL,
    [CreditTermId]            INT             NULL,
    [CreditLimitName]         VARCHAR (50)    NULL,
    [CreditTermName]          VARCHAR (50)    NULL,
    [VersionNumber]           VARCHAR (50)    NULL,
    [TotalFreight]            DECIMAL (20, 2) NULL,
    [TotalCharges]            DECIMAL (20, 2) NULL,
    [FreightBilingMethodId]   INT             NULL,
    [ChargesBilingMethodId]   INT             NULL,
    [EnforceEffectiveDate]    DATETIME2 (7)   NULL,
    [IsEnforceApproval]       BIT             NULL,
    [Level1]                  VARCHAR (200)   NULL,
    [Level2]                  VARCHAR (200)   NULL,
    [Level3]                  VARCHAR (200)   NULL,
    [Level4]                  VARCHAR (200)   NULL,
    CONSTRAINT [PK_SalesOrder] PRIMARY KEY CLUSTERED ([SalesOrderId] ASC),
    CONSTRAINT [FK_SalesOrder_AccountTypeId] FOREIGN KEY ([AccountTypeId]) REFERENCES [dbo].[CustomerType] ([CustomerTypeId]),
    CONSTRAINT [FK_SalesOrder_AgentId] FOREIGN KEY ([AgentId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_ApprovedById] FOREIGN KEY ([ApprovedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_CreditTerms] FOREIGN KEY ([CreditTermId]) REFERENCES [dbo].[CreditTerms] ([CreditTermsId]),
    CONSTRAINT [FK_SalesOrder_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_SalesOrder_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_SalesOrder_CustomerSeviceRepId] FOREIGN KEY ([CustomerSeviceRepId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_CustomerWarning] FOREIGN KEY ([CustomerWarningId]) REFERENCES [dbo].[CustomerWarning] ([CustomerWarningId]),
    CONSTRAINT [FK_SalesOrder_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrder_SalesOrderQuoteId] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrder_SalesPersonId] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrder_StatusId] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[MasterSalesOrderQuoteStatus] ([Id])
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderAudit]

   ON  [dbo].[SalesOrder]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END