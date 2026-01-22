CREATE TABLE [dbo].[RepairOrderApprover] (
    [RoApproverId]  BIGINT IDENTITY (1, 1) NOT NULL,
    [RepairOrderId] BIGINT NOT NULL,
    CONSTRAINT [PK_RepairOrderApprovar] PRIMARY KEY CLUSTERED ([RoApproverId] ASC),
    CONSTRAINT [FK_RepairOrderApprovar_RepairOrder] FOREIGN KEY ([RepairOrderId]) REFERENCES [dbo].[RepairOrder] ([RepairOrderId])
);

