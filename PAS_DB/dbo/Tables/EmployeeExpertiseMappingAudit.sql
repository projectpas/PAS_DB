CREATE TABLE [dbo].[EmployeeExpertiseMappingAudit] (
    [AuditEmployeeExpertiseMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeExpertiseMappingId]      BIGINT        NOT NULL,
    [EmployeeId]                      BIGINT        NOT NULL,
    [EmployeeExpertiseIds]            INT           NOT NULL,
    [MasterCompanyId]                 INT           NOT NULL,
    [CreatedBy]                       VARCHAR (256) NOT NULL,
    [UpdatedBy]                       VARCHAR (256) NOT NULL,
    [CreatedDate]                     DATETIME2 (7) CONSTRAINT [DF_EmployeeExpertiseMappingAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                     DATETIME2 (7) CONSTRAINT [DF_EmployeeExpertiseMappingAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                        BIT           CONSTRAINT [DF_EmployeeExpertiseMappingAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT           CONSTRAINT [DF_EmployeeExpertiseMappingAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeExpertiseMappingAudit] PRIMARY KEY CLUSTERED ([AuditEmployeeExpertiseMappingId] ASC)
);

