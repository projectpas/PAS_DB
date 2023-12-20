CREATE TABLE [dbo].[EmployeeUserRole] (
    [EmployeeUserRoleId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeId]         BIGINT         NOT NULL,
    [RoleId]             BIGINT         NOT NULL,
    [CreatedBy]          NVARCHAR (200) NOT NULL,
    [CreatedDate]        DATETIME       CONSTRAINT [DF_EmployeeUserRole_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedBy]          NVARCHAR (200) NOT NULL,
    [UpdatedDate]        DATETIME       CONSTRAINT [DF_EmployeeUserRole_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]           BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([EmployeeUserRoleId] ASC)
);

