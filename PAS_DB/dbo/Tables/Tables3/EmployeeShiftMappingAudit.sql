CREATE TABLE [dbo].[EmployeeShiftMappingAudit] (
    [EmployeeShiftMappingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeShiftMappingId]      BIGINT        NOT NULL,
    [EmployeeId]                  BIGINT        NOT NULL,
    [ShiftId]                     BIGINT        NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [DF_EmployeeShiftMappingAudit_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [DF_EmployeeShiftMappingAudit_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [DF_EmployeeShiftMappingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_EmployeeShiftMappingAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeShiftMappingAudit] PRIMARY KEY CLUSTERED ([EmployeeShiftMappingAuditId] ASC)
);

