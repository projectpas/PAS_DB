CREATE TABLE [dbo].[EmployeeLeaveTypeAudit] (
    [AuditEmployeeLeaveTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeLeaveTypeId]      TINYINT        NOT NULL,
    [Description]              VARCHAR (MAX)  NULL,
    [IsActive]                 BIT            NOT NULL,
    [LeaveType]                VARCHAR (256)  NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [IsDeleted]                BIT            NOT NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [CreatedDate]              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  NOT NULL,
    CONSTRAINT [PK_EmployeeLeaveTypeAudit] PRIMARY KEY CLUSTERED ([AuditEmployeeLeaveTypeId] ASC)
);

