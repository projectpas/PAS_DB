CREATE TABLE [dbo].[PurchaseOrderApproval] (
    [PurchaseOrderApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId]         BIGINT         NOT NULL,
    [PurchaseOrderPartId]     BIGINT         NOT NULL,
    [Memo]                    NVARCHAR (MAX) NULL,
    [SentDate]                DATETIME2 (7)  NULL,
    [ApprovedDate]            DATETIME2 (7)  NULL,
    [ApprovedById]            BIGINT         NULL,
    [ApprovedByName]          VARCHAR (200)  NULL,
    [RejectedDate]            DATETIME2 (7)  NULL,
    [RejectedBy]              BIGINT         NULL,
    [RejectedByName]          VARCHAR (200)  NULL,
    [StatusId]                INT            NULL,
    [StatusName]              VARCHAR (50)   NULL,
    [ActionId]                INT            NULL,
    [MasterCompanyId]         INT            NOT NULL,
    [CreatedBy]               VARCHAR (256)  NOT NULL,
    [UpdatedBy]               VARCHAR (256)  NOT NULL,
    [CreatedDate]             DATETIME2 (7)  NOT NULL,
    [UpdatedDate]             DATETIME2 (7)  NOT NULL,
    [IsActive]                BIT            CONSTRAINT [PurchaseOrderApprovals_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT            CONSTRAINT [PurchaseOrderApprovals_DC_Delete] DEFAULT ((0)) NOT NULL,
    [InternalSentToId]        BIGINT         NULL,
    [InternalSentToName]      VARCHAR (100)  NULL,
    [InternalSentById]        BIGINT         NULL,
    CONSTRAINT [PK_PurchaseOrderApprovals] PRIMARY KEY CLUSTERED ([PurchaseOrderApprovalId] ASC),
    CONSTRAINT [FK_PurchaseOrderApproval_ApprovalStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[ApprovalStatus] ([ApprovalStatusId]),
    CONSTRAINT [FK_PurchaseOrderApproval_EmployeeApprovedby] FOREIGN KEY ([ApprovedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_PurchaseOrderApproval_EmployeeRejectedBy] FOREIGN KEY ([RejectedBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_PurchaseOrderApproval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_PurchaseOrderApproval_PurchaseOrder] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId]),
    CONSTRAINT [FK_PurchaseOrderApproval_PurchaseOrderPart] FOREIGN KEY ([PurchaseOrderPartId]) REFERENCES [dbo].[PurchaseOrderPart] ([PurchaseOrderPartRecordId])
);


GO




-- =============================================

create TRIGGER [dbo].[Trg_PurchaseOrderApprovalAudit]

   ON  [dbo].[PurchaseOrderApproval]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO PurchaseOrderApprovalAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END