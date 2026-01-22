CREATE TABLE [dbo].[EmployeeCertificationType] (
    [EmployeeCertificationTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]                 VARCHAR (100)  NOT NULL,
    [Memo]                        NVARCHAR (MAX) NULL,
    [MastercompanyId]             INT            NOT NULL,
    [CreatedBy]                   VARCHAR (255)  NOT NULL,
    [UpdatedBy]                   VARCHAR (255)  NOT NULL,
    [CreatedDate]                 DATETIME2 (7)  CONSTRAINT [EmployeeLicenseType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)  CONSTRAINT [EmployeeLicenseType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                    BIT            CONSTRAINT [EmployeeLicenseType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                   BIT            CONSTRAINT [EmployeeLicenseType_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeCertificationType] PRIMARY KEY CLUSTERED ([EmployeeCertificationTypeId] ASC),
    CONSTRAINT [FK_EmployeeCertificationType_MasterCompany] FOREIGN KEY ([MastercompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_EmployeeLicenseType] UNIQUE NONCLUSTERED ([Description] ASC, [MastercompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_EmployeeLicenseTypeAudit] ON

[dbo].[EmployeeCertificationType]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[EmployeeCertificationTypeAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END
GO




CREATE TRIGGER [dbo].[Trg_EmployeeCertificationTypeAudit] ON

[dbo].[EmployeeCertificationType]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[EmployeeCertificationTypeAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END