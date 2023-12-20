CREATE TABLE [dbo].[EmployeeCertification] (
    [EmployeeCertificationId]     BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]                  BIGINT        NOT NULL,
    [CertificationNumber]         VARCHAR (30)  NULL,
    [EmployeeCertificationTypeId] BIGINT        NULL,
    [CertifyingInstitution]       VARCHAR (100) NULL,
    [CertificationDate]           DATETIME2 (7) NULL,
    [IsCertificationInForce]      BIT           CONSTRAINT [EmployeeLicensure_DC_IsLicenseInForce] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) CONSTRAINT [EmployeeLicensure_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) CONSTRAINT [EmployeeLicensure_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT           CONSTRAINT [EmployeeLicensure_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [ExpirationDate]              DATETIME2 (7) NULL,
    [IsExpirationDate]            BIT           CONSTRAINT [EmployeeLicensure_DC_IsExpirationDate] DEFAULT ((0)) NOT NULL,
    [IsDeleted]                   BIT           CONSTRAINT [DF_EmployeeLicensure_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeCertification] PRIMARY KEY CLUSTERED ([EmployeeCertificationId] ASC),
    CONSTRAINT [FK_EmployeeCertification_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_EmployeeCertification_EmployeeCertificationType] FOREIGN KEY ([EmployeeCertificationTypeId]) REFERENCES [dbo].[EmployeeCertificationType] ([EmployeeCertificationTypeId]),
    CONSTRAINT [FK_EmployeeCertification_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO


Create TRIGGER [dbo].[Trg_EmployeeCertificationAudit] ON

[dbo].[EmployeeCertification]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[EmployeeCertificationAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END