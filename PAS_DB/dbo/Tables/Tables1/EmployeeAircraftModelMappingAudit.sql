CREATE TABLE [dbo].[EmployeeAircraftModelMappingAudit] (
    [EmployeeAircraftModelMappingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeAircraftModelMappingId]      BIGINT        NOT NULL,
    [EmployeeId]                          BIGINT        NOT NULL,
    [AircraftManufacturerId]              INT           NOT NULL,
    [AircraftModelId]                     BIGINT        NOT NULL,
    [MasterCompanyId]                     INT           NOT NULL,
    [CreatedBy]                           VARCHAR (256) NOT NULL,
    [UpdatedBy]                           VARCHAR (256) NOT NULL,
    [CreatedDate]                         DATETIME2 (7) CONSTRAINT [DF_EmployeeAircraftModelMappingAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                         DATETIME2 (7) CONSTRAINT [DF_EmployeeAircraftModelMappingAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                            BIT           CONSTRAINT [DF_EmployeeAircraftModelMappingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                           BIT           CONSTRAINT [DF_EmployeeAircraftModelMappingAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeAircraftModelMappingAudit] PRIMARY KEY CLUSTERED ([EmployeeAircraftModelMappingAuditId] ASC)
);

