CREATE TABLE [dbo].[RepairOrderApproverList] (
    [RoApproverListId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [RoApproverId]     BIGINT        NOT NULL,
    [EmployeeId]       BIGINT        NULL,
    [Level]            INT           NULL,
    [StatusId]         INT           NULL,
    [CreatedBy]        VARCHAR (100) NULL,
    [UpdatedBy]        VARCHAR (100) NULL,
    [CreatedDate]      DATETIME2 (7) NULL,
    [UpdatedDate]      DATETIME2 (7) NULL,
    CONSTRAINT [PK_RepairOrderApprovarList] PRIMARY KEY CLUSTERED ([RoApproverListId] ASC),
    CONSTRAINT [FK_RepairOrderApprovarList_RepairOrderApprovar] FOREIGN KEY ([RoApproverId]) REFERENCES [dbo].[RepairOrderApprover] ([RoApproverId])
);


GO




CREATE TRIGGER [dbo].[Trg_RepairOrderApproverListAudit]

   ON  [dbo].[RepairOrderApproverList]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO RepairOrderApproverListAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END