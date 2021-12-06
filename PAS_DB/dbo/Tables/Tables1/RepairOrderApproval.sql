CREATE TABLE [dbo].[RepairOrderApproval] (
    [RepairOrderApprovalId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [RepairOrderId]         BIGINT         NOT NULL,
    [RepairOrderPartId]     BIGINT         NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [SentDate]              DATETIME2 (7)  NULL,
    [ApprovedDate]          DATETIME2 (7)  NULL,
    [ApprovedById]          BIGINT         NULL,
    [RejectedDate]          DATETIME2 (7)  NULL,
    [RejectedBy]            BIGINT         NULL,
    [StatusId]              INT            NULL,
    [ActionId]              INT            NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            CONSTRAINT [RepairOrderApprovals_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [RepairOrderApprovals_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ApprovedByName]        VARCHAR (256)  NULL,
    [RejectedByName]        VARCHAR (256)  NULL,
    [StatusName]            VARCHAR (50)   NULL,
    CONSTRAINT [PK_RepairOrderApprovals] PRIMARY KEY CLUSTERED ([RepairOrderApprovalId] ASC),
    CONSTRAINT [FK_RepairOrderApproval_ApprovalStatus] FOREIGN KEY ([StatusId]) REFERENCES [dbo].[ApprovalStatus] ([ApprovalStatusId]),
    CONSTRAINT [FK_RepairOrderApproval_EmployeeApprovedby] FOREIGN KEY ([ApprovedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_RepairOrderApproval_EmployeeRejectedBy] FOREIGN KEY ([RejectedBy]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_RepairOrderApproval_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_RepairOrderApproval_RepairOrder] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId]),
    CONSTRAINT [FK_RepairOrderApproval_RepairOrderPart] FOREIGN KEY ([RepairOrderPartId]) REFERENCES [dbo].[RepairOrderPart] ([RepairOrderPartRecordId])
);


GO






-- =============================================

create TRIGGER [dbo].[Trg_RepairOrderApprovalAudit]

   ON  [dbo].[RepairOrderApproval]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO RepairOrderApprovalAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END