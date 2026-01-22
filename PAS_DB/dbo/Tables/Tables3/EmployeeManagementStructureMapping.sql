CREATE TABLE [dbo].[EmployeeManagementStructureMapping] (
    [EmployeeManagementStructureMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]                           BIGINT        NOT NULL,
    [ManagementStructureId]                BIGINT        NOT NULL,
    [MasterCompanyId]                      INT           NOT NULL,
    [CreatedBy]                            VARCHAR (256) NOT NULL,
    [CreatedDate]                          DATETIME2 (7) CONSTRAINT [DF_EmployeeManagementStructureMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                            VARCHAR (256) NOT NULL,
    [UpdatedDate]                          DATETIME2 (7) CONSTRAINT [DF_EmployeeManagementStructureMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                             BIT           CONSTRAINT [DF_EmployeeManagementStructureMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                            BIT           CONSTRAINT [DF_EmployeeManagementStructureMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeManagementStructureMapping] PRIMARY KEY CLUSTERED ([EmployeeManagementStructureMappingId] ASC)
);

