CREATE TABLE [dbo].[ItemMasterExchangeLoan] (
    [ItemMasterLoanExchId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]          BIGINT          NOT NULL,
    [IsLoan]                BIT             NULL,
    [IsExchange]            BIT             NULL,
    [ExchangeCurrencyId]    BIGINT          NULL,
    [LoanCurrencyId]        BIGINT          NULL,
    [ExchangeListPrice]     DECIMAL (18, 2) NULL,
    [ExchangeCorePrice]     DECIMAL (18, 2) NULL,
    [ExchangeOverhaulPrice] DECIMAL (18, 2) NULL,
    [ExchangeOutrightPrice] DECIMAL (18, 2) NULL,
    [ExchangeCoreCost]      DECIMAL (18, 2) NULL,
    [LoanCorePrice]         DECIMAL (18, 2) NULL,
    [LoanOutrightPrice]     DECIMAL (18, 2) NULL,
    [LoanFees]              DECIMAL (18, 2) NULL,
    [MasterCompanyId]       INT             NULL,
    [CreatedBy]             VARCHAR (256)   NULL,
    [CreatedDate]           DATETIME2 (7)   CONSTRAINT [DF_ItemMasterExchangeLoan_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedBy]             VARCHAR (256)   NULL,
    [UpdatedDate]           DATETIME2 (7)   CONSTRAINT [DF_ItemMasterExchangeLoan_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]              BIT             CONSTRAINT [DF_ItemMasterExchangeLoan1_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]             BIT             CONSTRAINT [DF_ItemMasterExchangeLoan1_IsDeleted] DEFAULT ((0)) NULL,
    [ExchangeOverhaulCost]  DECIMAL (18, 2) NULL,
    [EFcogs]                INT             DEFAULT ((0)) NOT NULL,
    [OPcogs]                INT             DEFAULT ((0)) NOT NULL,
    [EFcogsamount]          DECIMAL (18, 2) NULL,
    [OPcogsamount]          DECIMAL (18, 2) NULL,
    CONSTRAINT [PK_ItemMasterExchangeLoan1] PRIMARY KEY CLUSTERED ([ItemMasterLoanExchId] ASC),
    CONSTRAINT [FK_ItemMasterExchangeLoan_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId])
);




GO








CREATE TRIGGER [dbo].[Trg_ItemMasterExchangeLoanAudit]

   ON  [dbo].[ItemMasterExchangeLoan]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO [dbo].[ItemMasterExchangeLoanAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END