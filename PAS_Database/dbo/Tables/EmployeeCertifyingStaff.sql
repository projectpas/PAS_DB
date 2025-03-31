CREATE TABLE [dbo].[EmployeeCertifyingStaff] (
    [EmployeeCertifyingStaffId] INT            IDENTITY (1, 1) NOT NULL,
    [IsCertifyingStaff]         NVARCHAR (200) NULL,
    [Description]               VARCHAR (200)  NULL,
    [MasterCompanyId]           INT            NULL,
    [CreatedBy]                 VARCHAR (256)  NULL,
    [UpdatedBy]                 VARCHAR (256)  NULL,
    [CreatedDate]               DATETIME2 (7)  NULL,
    [UpdatedDate]               DATETIME2 (7)  NULL,
    [IsActive]                  BIT            NULL,
    [IsDeleted]                 BIT            NULL,
    CONSTRAINT [PK_EmployeeCertifyingStaff] PRIMARY KEY CLUSTERED ([EmployeeCertifyingStaffId] ASC)
);

