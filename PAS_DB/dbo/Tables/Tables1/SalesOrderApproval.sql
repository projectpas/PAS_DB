CREATE TABLE [dbo].[SalesOrderApproval] (
    [SalesOrderApprovalId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [SalesOrderId]           BIGINT         NOT NULL,
    [SalesOrderPartId]       BIGINT         NOT NULL,
    [SalesOrderQuoteId]      BIGINT         NULL,
    [SalesOrderQuotePartId]  BIGINT         NULL,
    [CustomerId]             BIGINT         NOT NULL,
    [InternalMemo]           NVARCHAR (MAX) NULL,
    [InternalSentDate]       DATETIME2 (7)  NULL,
    [InternalApprovedDate]   DATETIME2 (7)  NULL,
    [InternalApprovedById]   BIGINT         NULL,
    [CustomerSentDate]       DATETIME2 (7)  NULL,
    [CustomerApprovedDate]   DATETIME2 (7)  NULL,
    [CustomerApprovedById]   BIGINT         NULL,
    [ApprovalActionId]       INT            NULL,
    [CustomerStatusId]       INT            NULL,
    [InternalStatusId]       INT            NULL,
    [CustomerMemo]           NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_SalesOrderApproval_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_SalesOrderApproval_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [SalesOrderApprovals_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [SalesOrderApprovals_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Customer]               VARCHAR (100)  NULL,
    [InternalApprovedBy]     VARCHAR (100)  NULL,
    [CustomerApprovedBy]     VARCHAR (100)  NULL,
    [ApprovalAction]         VARCHAR (50)   NULL,
    [CustomerStatus]         VARCHAR (50)   NULL,
    [InternalStatus]         VARCHAR (50)   NULL,
    [RejectedById]           BIGINT         NULL,
    [RejectedByName]         VARCHAR (100)  NULL,
    [RejectedDate]           DATETIME2 (7)  NULL,
    [InternalRejectedById]   BIGINT         NULL,
    [InternalRejectedByName] VARCHAR (100)  NULL,
    [InternalRejectedDate]   DATETIME2 (7)  NULL,
    CONSTRAINT [PK_SalesOrderApproval] PRIMARY KEY CLUSTERED ([SalesOrderApprovalId] ASC),
    CONSTRAINT [FK_SalesOrderApproval_CustomerApprovedById] FOREIGN KEY ([CustomerApprovedById]) REFERENCES [dbo].[Contact] ([ContactId]),
    CONSTRAINT [FK_SalesOrderApproval_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_SalesOrderApproval_InternalApprovedById] FOREIGN KEY ([InternalApprovedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_SalesOrderApproval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_SalesOrderApproval_SalesOrder] FOREIGN KEY ([SalesOrderId]) REFERENCES [dbo].[SalesOrder] ([SalesOrderId]),
    CONSTRAINT [FK_SalesOrderApproval_SalesOrderPart] FOREIGN KEY ([SalesOrderPartId]) REFERENCES [dbo].[SalesOrderPart] ([SalesOrderPartId]),
    CONSTRAINT [FK_SalesOrderApproval_SalesOrderQuote] FOREIGN KEY ([SalesOrderQuoteId]) REFERENCES [dbo].[SalesOrderQuote] ([SalesOrderQuoteId]),
    CONSTRAINT [FK_SalesOrderApproval_SalesOrderQuotePart] FOREIGN KEY ([SalesOrderQuotePartId]) REFERENCES [dbo].[SalesOrderQuotePart] ([SalesOrderQuotePartId])
);




GO


CREATE TRIGGER [dbo].[Trg_SalesOrderApprovalAudit]

   ON  [dbo].[SalesOrderApproval]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO SalesOrderApprovalAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END