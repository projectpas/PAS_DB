CREATE TYPE [dbo].[EmployeeUserRoleType] AS TABLE (
    [EmployeeUserRoleId] BIGINT        NULL,
    [EmployeeId]         BIGINT        NULL,
    [RoleId]             BIGINT        NULL,
    [IsActive]           BIT           NULL,
    [IsDeleted]          BIT           NULL,
    [CreatedBy]          VARCHAR (256) NULL,
    [UpdatedBy]          VARCHAR (256) NULL,
    [UpdatedDate]        DATETIME2 (7) NULL,
    [CreatedDate]        DATETIME2 (7) NULL);

