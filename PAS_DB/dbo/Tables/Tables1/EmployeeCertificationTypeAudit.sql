CREATE TABLE [dbo].[EmployeeCertificationTypeAudit] (
    [EmployeeCertificationTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeCertificationTypeId]      BIGINT         NOT NULL,
    [Description]                      VARCHAR (100)  NOT NULL,
    [Memo]                             NVARCHAR (MAX) NULL,
    [MastercompanyId]                  INT            NOT NULL,
    [CreatedBy]                        VARCHAR (255)  NOT NULL,
    [UpdatedBy]                        VARCHAR (255)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                      DATETIME2 (7)  NOT NULL,
    [IsActive]                         BIT            NOT NULL,
    [IsDeleted]                        BIT            NOT NULL,
    CONSTRAINT [PK_EmployeeLicenseTypeAudit] PRIMARY KEY CLUSTERED ([EmployeeCertificationTypeAuditId] ASC)
);

