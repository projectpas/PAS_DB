CREATE TABLE [dbo].[EmployeeAudit] (
    [AuditEmployeeId]         BIGINT          IDENTITY (1, 1) NOT NULL,
    [EmployeeId]              BIGINT          NOT NULL,
    [EmployeeCode]            VARCHAR (50)    NULL,
    [EmployeeIdAsPerPayroll]  VARCHAR (50)    NULL,
    [FirstName]               VARCHAR (30)    NOT NULL,
    [LastName]                VARCHAR (30)    NOT NULL,
    [MiddleName]              VARCHAR (30)    NULL,
    [JobTitleId]              SMALLINT        NULL,
    [EmployeeExpertiseId]     SMALLINT        NULL,
    [DateOfBirth]             DATETIME2 (7)   NULL,
    [StartDate]               DATETIME2 (7)   NULL,
    [MobilePhone]             VARCHAR (20)    NULL,
    [WorkPhone]               VARCHAR (20)    NULL,
    [Fax]                     VARCHAR (20)    NULL,
    [Email]                   VARCHAR (200)   NULL,
    [SSN]                     VARCHAR (20)    NULL,
    [InMultipleShifts]        BIT             NULL,
    [AllowOvertime]           BIT             NULL,
    [AllowDoubleTime]         BIT             NULL,
    [IsHourly]                BIT             NULL,
    [HourlyPay]               DECIMAL (18, 2) NULL,
    [EmployeeCertifyingStaff] BIT             NULL,
    [SupervisorId]            BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [CreatedDate]             DATETIME2 (7)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   NOT NULL,
    [IsActive]                BIT             NULL,
    [IsDeleted]               BIT             NULL,
    [ManagementStructureId]   BIGINT          NULL,
    [LegalEntityId]           BIGINT          NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [CurrencyId]              INT             NULL,
    [StationId]               BIGINT          NULL,
    [AttachmentId]            BIGINT          NULL,
    [EmployeeExpIds]          VARCHAR (100)   NULL,
    [EmailSignature]          NVARCHAR (MAX)  NULL,
    [EmailSignatureLogo]      NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK_EmployeeAudit] PRIMARY KEY CLUSTERED ([AuditEmployeeId] ASC)
);









