CREATE TYPE [dbo].[EmployeeManagementStructureTVP] AS TABLE (
    [EmployeeManagementId]  BIGINT        NULL,
    [EmployeeId]            BIGINT        NULL,
    [ManagementStructureId] BIGINT        NULL,
    [MasterCompanyId]       INT           NULL,
    [CreatedBy]             VARCHAR (256) NULL,
    [CreatedDate]           DATETIME2 (7) NULL,
    [UpdatedBy]             VARCHAR (256) NULL,
    [UpdatedDate]           DATETIME2 (7) NULL,
    [IsActive]              BIT           NULL,
    [IsDeleted]             BIT           NULL);

