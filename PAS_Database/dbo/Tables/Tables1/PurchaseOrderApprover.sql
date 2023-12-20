CREATE TABLE [dbo].[PurchaseOrderApprover] (
    [POApproverId]    BIGINT IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderId] BIGINT NOT NULL,
    CONSTRAINT [PK_PurchaseOrderApprovers] PRIMARY KEY CLUSTERED ([POApproverId] ASC),
    CONSTRAINT [FK_PurchaseOrderApprover_PurchaseOrder] FOREIGN KEY ([PurchaseOrderId]) REFERENCES [dbo].[PurchaseOrder] ([PurchaseOrderId])
);

