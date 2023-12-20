CREATE TABLE [dbo].[EmployeeTrainingTypeAudit] (
    [AuditEmployeeTrainingTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeTrainingTypeId]      BIGINT         NOT NULL,
    [Description]                 VARCHAR (MAX)  NULL,
    [TrainingType]                VARCHAR (256)  NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [IsDeleted]                   BIT            NOT NULL,
    [MasterCompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (256)  NOT NULL,
    [UpdatedBy]                   VARCHAR (256)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  NOT NULL,
    [IsActive]                    BIT            NOT NULL,
    CONSTRAINT [PK_EmployeeTrainingTypeAudit] PRIMARY KEY CLUSTERED ([AuditEmployeeTrainingTypeId] ASC)
);

