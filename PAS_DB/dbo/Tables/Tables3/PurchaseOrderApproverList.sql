CREATE TABLE [dbo].[PurchaseOrderApproverList] (
    [POApproverListId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [POApproverId]     BIGINT        NOT NULL,
    [EmployeeId]       BIGINT        NOT NULL,
    [Level]            INT           NOT NULL,
    [StatusId]         INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) NOT NULL,
    CONSTRAINT [PK_PurchaseOrderApproverList] PRIMARY KEY CLUSTERED ([POApproverListId] ASC),
    CONSTRAINT [FK_PurchaseOrderApproverList_PurchaseOrderApprover] FOREIGN KEY ([POApproverId]) REFERENCES [dbo].[PurchaseOrderApprover] ([POApproverId])
);


GO




CREATE TRIGGER [dbo].[Trg_PurchaseOrderApproverListAudit]

   ON  [dbo].[PurchaseOrderApproverList]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO PurchaseOrderApproverListAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END