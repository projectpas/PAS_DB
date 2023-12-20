CREATE TABLE [dbo].[RepairOrderApproverListAudit] (
    [RoApproverListAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [RoApproverListId]      BIGINT        NOT NULL,
    [RoApproverId]          BIGINT        NOT NULL,
    [EmployeeId]            BIGINT        NULL,
    [Level]                 INT           NULL,
    [StatusId]              INT           NULL,
    [CreatedBy]             VARCHAR (100) NULL,
    [UpdatedBy]             VARCHAR (100) NULL,
    [CreatedDate]           DATETIME2 (7) NULL,
    [UpdatedDate]           DATETIME2 (7) NULL,
    CONSTRAINT [PK_RepairOrderApprovarListAudit] PRIMARY KEY CLUSTERED ([RoApproverListAuditId] ASC)
);

