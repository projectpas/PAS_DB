CREATE TABLE [dbo].[WorkOrderQuote] (
    [WorkOrderQuoteId]          BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]               BIGINT          NOT NULL,
    [QuoteNumber]               VARCHAR (100)   NULL,
    [OpenDate]                  DATETIME2 (7)   NOT NULL,
    [QuoteDueDate]              DATETIME2 (7)   NOT NULL,
    [ValidForDays]              INT             NULL,
    [ExpirationDate]            DATETIME2 (7)   NULL,
    [QuoteStatusId]             BIGINT          NOT NULL,
    [CustomerId]                BIGINT          NOT NULL,
    [CurrencyId]                INT             NOT NULL,
    [DSO]                       VARCHAR (256)   NULL,
    [AccountsReceivableBalance] DECIMAL (20, 3) NULL,
    [SalesPersonId]             BIGINT          NULL,
    [EmployeeId]                BIGINT          NOT NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuote_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuote_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [DF_WorkOrderQuote_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [DF_WorkOrderQuote_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [Warnings]                  VARCHAR (256)   NULL,
    [SentDate]                  DATETIME2 (7)   NULL,
    [ApprovedDate]              DATETIME2 (7)   NULL,
    [VersionNo]                 VARCHAR (20)    NULL,
    [IsApprovalBypass]          BIT             CONSTRAINT [WorkOrderQuote_DC_IsApprovalBypass] DEFAULT ((0)) NULL,
    [QuoteParentId]             BIGINT          NULL,
    [IsVersionIncrease]         BIT             DEFAULT ((0)) NOT NULL,
    [Notes]                     NVARCHAR (MAX)  NULL,
    [CustomerName]              VARCHAR (200)   NULL,
    [CustomerContact]           VARCHAR (200)   NULL,
    [CreditLimit]               DECIMAL (18, 2) NULL,
    [CreditTerms]               VARCHAR (200)   NULL,
    CONSTRAINT [PK_WorkOrderQuote] PRIMARY KEY CLUSTERED ([WorkOrderQuoteId] ASC),
    CONSTRAINT [FK_WorkOrderQuote_Currency] FOREIGN KEY ([CurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_WorkOrderQuote_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderQuote_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderQuote_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderQuote_QuoteParentId] FOREIGN KEY ([QuoteParentId]) REFERENCES [dbo].[WorkOrderQuote] ([WorkOrderQuoteId]),
    CONSTRAINT [FK_WorkOrderQuote_SalesPerson] FOREIGN KEY ([SalesPersonId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_WorkOrderQuote_WorkOrder] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_WorkOrderQuote_WorkOrderQuoteStatus] FOREIGN KEY ([QuoteStatusId]) REFERENCES [dbo].[WorkOrderQuoteStatus] ([WorkOrderQuoteStatusId])
);


GO


----------------------------------------------

CREATE TRIGGER [dbo].[Trg_WorkOrderQuoteAudit]

   ON  [dbo].[WorkOrderQuote]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[WorkOrderQuoteAudit] 

    SELECT * 

	FROM INSERTED 

	SET NOCOUNT ON;



END