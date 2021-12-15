CREATE TABLE [dbo].[SalesOrderQuoteApproval] (
    [SalesOrderQuoteApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderQuoteId]         BIGINT         NOT NULL,
    [SalesOrderQuotePartId]     BIGINT         NOT NULL,
    [CustomerId]                BIGINT         NOT NULL,
    [InternalMemo]              NVARCHAR (MAX) NULL,
    [InternalSentDate]          DATETIME2 (7)  NULL,
    [InternalApprovedDate]      DATETIME2 (7)  NULL,
    [InternalApprovedById]      BIGINT         NULL,
    [CustomerSentDate]          DATETIME2 (7)  NULL,
    [CustomerApprovedDate]      DATETIME2 (7)  NULL,
    [CustomerApprovedById]      BIGINT         NULL,
    [ApprovalActionId]          INT            NULL,
    [CustomerStatusId]          INT            NULL,
    [InternalStatusId]          INT            NULL,
    [CustomerMemo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]           INT            NOT NULL,
    [CreatedBy]                 VARCHAR (256)  NOT NULL,
    [UpdatedBy]                 VARCHAR (256)  NOT NULL,
    [CreatedDate]               DATETIME2 (7)  CONSTRAINT [DF_SalesOrderQuoteApproval_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)  CONSTRAINT [DF_SalesOrderQuoteApproval_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT            CONSTRAINT [SalesOrderQuoteApprovals_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT            CONSTRAINT [SalesOrderQuoteApprovals_DC_Delete] DEFAULT ((0)) NOT NULL,
    [CustomerName]              VARCHAR (100)  NULL,
    [InternalApprovedBy]        VARCHAR (100)  NULL,
    [CustomerApprovedBy]        VARCHAR (100)  NULL,
    [ApprovalAction]            VARCHAR (100)  NULL,
    [CustomerStatus]            VARCHAR (50)   NULL,
    [InternalStatus]            VARCHAR (50)   NULL,
    [RejectedById]              BIGINT         NULL,
    [RejectedByName]            VARCHAR (100)  NULL,
    [RejectedDate]              DATETIME2 (7)  NULL,
    CONSTRAINT [PK_SalesOrderQuoteApproval] PRIMARY KEY CLUSTERED ([SalesOrderQuoteApprovalId] ASC),
    CONSTRAINT [FK_SalesOrderQuoteApproval_CustomerApprovedById] FOREIGN KEY ([CustomerApprovedById]) REFERENCES [dbo].[Contact] ([ContactId]),
    CONSTRAINT [FK_SalesOrderQuoteApproval_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_SalesOrderQuoteApproval_InternalApprovedById] FOREIGN KEY ([InternalApprovedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderQuoteApproval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderQuoteApproval_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderQuoteApproval_SalesOrderQuotePart] FOREIGN KEY ([SalesOrderQuotePartId]) REFERENCES [dbo].[SalesOrderQuotePart] ([SalesOrderQuotePartId])
);






GO


CREATE TRIGGER [dbo].[Trg_SalesOrderQuoteApprovalAudit]

   ON  [dbo].[SalesOrderQuoteApproval]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderQuoteApprovalAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END