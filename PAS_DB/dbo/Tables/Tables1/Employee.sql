CREATE TABLE [dbo].[Employee] (
    [EmployeeId]              BIGINT          IDENTITY (1, 1) NOT NULL,
    [EmployeeCode]            VARCHAR (50)    NULL,
    [EmployeeIdAsPerPayroll]  VARCHAR (50)    NULL,
    [FirstName]               VARCHAR (50)    NOT NULL,
    [LastName]                VARCHAR (30)    NOT NULL,
    [MiddleName]              VARCHAR (30)    NULL,
    [JobTitleId]              SMALLINT        NOT NULL,
    [EmployeeExpertiseId]     SMALLINT        NOT NULL,
    [DateOfBirth]             DATETIME2 (7)   NULL,
    [StartDate]               DATETIME2 (7)   NOT NULL,
    [MobilePhone]             VARCHAR (20)    NULL,
    [WorkPhone]               VARCHAR (20)    NULL,
    [Fax]                     VARCHAR (20)    NULL,
    [Email]                   VARCHAR (200)   NULL,
    [SSN]                     VARCHAR (20)    NULL,
    [InMultipleShifts]        BIT             CONSTRAINT [DF_Employee_InMultipleShifts] DEFAULT ((0)) NOT NULL,
    [AllowOvertime]           BIT             CONSTRAINT [DF_Employee_AllowOvertime] DEFAULT ((0)) NOT NULL,
    [AllowDoubleTime]         BIT             CONSTRAINT [DF_Employee_AllowDoubleTime] DEFAULT ((0)) NOT NULL,
    [IsHourly]                BIT             CONSTRAINT [DF_Employee_IsHourly] DEFAULT ((0)) NULL,
    [HourlyPay]               DECIMAL (18, 2) NULL,
    [EmployeeCertifyingStaff] BIT             CONSTRAINT [DF_Employee_EmployeeCertifyingStaff] DEFAULT ((0)) NOT NULL,
    [SupervisorId]            BIGINT          NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_Employee_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_Employee_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_Employee_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_Employee_isDeleted] DEFAULT ((0)) NOT NULL,
    [ManagementStructureId]   BIGINT          NOT NULL,
    [LegalEntityId]           BIGINT          NULL,
    [Memo]                    NVARCHAR (MAX)  NULL,
    [CurrencyId]              INT             NULL,
    [StationId]               BIGINT          NULL,
    [AttachmentId]            BIGINT          NULL,
    [EmployeeExpIds]          VARCHAR (100)   NULL,
    [EmailSignature]          NVARCHAR (MAX)  NULL,
    CONSTRAINT [PK_Employee] PRIMARY KEY CLUSTERED ([EmployeeId] ASC),
    FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_Employee_JobTitle] FOREIGN KEY ([JobTitleId]) REFERENCES [dbo].[JobTitle] ([JobTitleId]),
    CONSTRAINT [FK_Employee_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Employee_Station] FOREIGN KEY ([StationId]) REFERENCES [dbo].[EmployeeStation] ([EmployeeStationId])
);










GO






CREATE TRIGGER [dbo].[Trg_EmployeeAudit]

   ON  [dbo].[Employee]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[EmployeeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END