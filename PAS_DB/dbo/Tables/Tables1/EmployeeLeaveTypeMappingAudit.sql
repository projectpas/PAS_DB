CREATE TABLE [dbo].[EmployeeLeaveTypeMappingAudit] (
    [EmployeeLeaveTypeMappingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeLeaveTypeMappingId]      BIGINT        NOT NULL,
    [EmployeeId]                      BIGINT        NOT NULL,
    [EmployeeLeaveTypeId]             INT           NOT NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) CONSTRAINT [DF_EmployeeLeaveTypeMappingAudit_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) CONSTRAINT [DF_EmployeeLeaveTypeMappingAudit_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                        BIT           CONSTRAINT [DF_EmployeeLeaveTypeMappingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           CONSTRAINT [DF_EmployeeLeaveTypeMappingAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeLeaveTypeMappingAudit] PRIMARY KEY CLUSTERED ([EmployeeLeaveTypeMappingAuditId] ASC)
);

