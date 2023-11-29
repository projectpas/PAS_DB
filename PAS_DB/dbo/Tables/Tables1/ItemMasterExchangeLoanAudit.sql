CREATE TABLE [dbo].[ItemMasterExchangeLoanAudit] (
    [ItemMasterLoanExchAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemMasterLoanExchId]      BIGINT          NOT NULL,
    [ItemMasterId]              BIGINT          NOT NULL,
    [IsLoan]                    BIT             NULL,
    [IsExchange]                BIT             NULL,
    [ExchangeCurrencyId]        BIGINT          NULL,
    [LoanCurrencyId]            BIGINT          NULL,
    [ExchangeListPrice]         DECIMAL (18, 2) NULL,
    [ExchangeCorePrice]         DECIMAL (18, 2) NULL,
    [ExchangeOverhaulPrice]     DECIMAL (18, 2) NULL,
    [ExchangeOutrightPrice]     DECIMAL (18, 2) NULL,
    [ExchangeCoreCost]          DECIMAL (18, 2) NULL,
    [LoanCorePrice]             DECIMAL (18, 2) NULL,
    [LoanOutrightPrice]         DECIMAL (18, 2) NULL,
    [LoanFees]                  DECIMAL (18, 2) NULL,
    [MasterCompanyId]           INT             NULL,
    [CreatedBy]                 VARCHAR (256)   NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_ItemMasterExchangeLoanAudit_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedBy]                 VARCHAR (256)   NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_ItemMasterExchangeLoanAudit_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_ItemMasterExchangeLoanAudit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_ItemMasterExchangeLoanAudit_IsDeleted] DEFAULT ((0)) NULL,
    [ExchangeOverhaulCost]      DECIMAL (18, 2) NULL,
    [EFcogs]                    INT             DEFAULT ((0)) NOT NULL,
    [OPcogs]                    INT             DEFAULT ((0)) NOT NULL,
    [EFcogsamount]              DECIMAL (18, 2) NULL,
    [OPcogsamount]              DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_ItemMasterExchangeLoanAudit] PRIMARY KEY CLUSTERED ([ItemMasterLoanExchAuditId] ASC)
);



