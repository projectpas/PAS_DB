CREATE TABLE [dbo].[WorkOrderApproval] (
    [WorkOrderApprovalId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkOrderId]          BIGINT         NOT NULL,
    [WorkOrderQuoteId]     BIGINT         NULL,
    [WorkOrderPartNoId]    BIGINT         NOT NULL,
    [CustomerId]           BIGINT         NOT NULL,
    [WorkOrderDetailId]    BIGINT         NULL,
    [InternalMemo]         NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [DF_WorkOrderApproval_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [DF_WorkOrderApproval_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [WorkOrderApprovals_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [WorkOrderApprovals_DC_Delete] DEFAULT ((0)) NOT NULL,
    [InternalSentDate]     DATETIME2 (7)  NULL,
    [InternalApprovedDate] DATETIME2 (7)  NULL,
    [InternalApprovedById] BIGINT         NULL,
    [CustomerSentDate]     DATETIME2 (7)  NULL,
    [CustomerApprovedDate] DATETIME2 (7)  NULL,
    [CustomerApprovedById] BIGINT         NULL,
    [ApprovalActionId]     INT            NULL,
    [CustomerStatusId]     INT            NULL,
    [InternalStatusId]     INT            NULL,
    [CustomerMemo]         NVARCHAR (MAX) NULL,
    [InternalRejectedDate] DATETIME       NULL,
    [InternalRejectedID]   BIGINT         NULL,
    [CustomerRejectedDate] DATETIME       NULL,
    [CustomerRejectedbyID] BIGINT         NULL,
    [InternalSentToId]     BIGINT         NULL,
    [InternalSentToName]   VARCHAR (100)  NULL,
    [InternalSentById]     BIGINT         NULL,
    CONSTRAINT [PK_WorkOrderApprovals] PRIMARY KEY CLUSTERED ([WorkOrderApprovalId] ASC),
    CONSTRAINT [FK_WorkOrderApproval_CustomerId] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_WorkOrderApproval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_WorkOrderApproval_WorkOrderId] FOREIGN KEY ([WorkOrderId]) REFERENCES [dbo].[WorkOrder] ([WorkOrderId]),
    CONSTRAINT [FK_WorkOrderApproval_WorkOrderPartNoId] FOREIGN KEY ([WorkOrderPartNoId]) REFERENCES [dbo].[WorkOrderPartNumber] ([ID]),
    CONSTRAINT [FK_WorkOrderApproval_WorkOrderQuoteId] FOREIGN KEY ([WorkOrderQuoteId]) REFERENCES [dbo].[WorkOrderQuote] ([WorkOrderQuoteId])
);


GO




CREATE TRIGGER [dbo].[Trg_WorkOrderApprovalAudit]

   ON  [dbo].[WorkOrderApproval]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WorkOrderApprovalAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END