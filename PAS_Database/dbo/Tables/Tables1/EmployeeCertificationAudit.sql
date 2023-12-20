CREATE TABLE [dbo].[EmployeeCertificationAudit] (
    [EmployeeCertificationAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeCertificationId]      BIGINT        NOT NULL,
    [EmployeeId]                   BIGINT        NOT NULL,
    [CertificationNumber]          VARCHAR (30)  NULL,
    [EmployeeCertificationTypeId]  BIGINT        NULL,
    [CertifyingInstitution]        VARCHAR (100) NULL,
    [CertificationDate]            DATETIME2 (7) NULL,
    [IsCertificationInForce]       BIT           NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) NOT NULL,
    [IsActive]                     BIT           NOT NULL,
    [ExpirationDate]               DATETIME2 (7) NULL,
    [IsExpirationDate]             BIT           NOT NULL,
    [IsDeleted]                    BIT           NOT NULL,
    CONSTRAINT [PK_EmployeeCertificationAudit] PRIMARY KEY CLUSTERED ([EmployeeCertificationAuditId] ASC)
);

