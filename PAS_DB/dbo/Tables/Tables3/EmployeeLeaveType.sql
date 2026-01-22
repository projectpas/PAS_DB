CREATE TABLE [dbo].[EmployeeLeaveType] (
    [EmployeeLeaveTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [Description]         VARCHAR (MAX)  NULL,
    [IsActive]            BIT            CONSTRAINT [DF_EmployeeLeaveType_IsActive] DEFAULT ((1)) NOT NULL,
    [LeaveType]           VARCHAR (256)  NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [IsDeleted]           BIT            DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [EmployeeLeaveType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [EmployeeLeaveType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    CONSTRAINT [PK_EmployeeLeaveType] PRIMARY KEY CLUSTERED ([EmployeeLeaveTypeId] ASC),
    CONSTRAINT [FK_EmployeeLeaveType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_EmployeeLeaveType] UNIQUE NONCLUSTERED ([LeaveType] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_EmployeeLeaveTypeAudit] ON [dbo].[EmployeeLeaveType]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 INSERT INTO [dbo].[EmployeeLeaveTypeAudit]  

 SELECT * FROM INSERTED  



 SET NOCOUNT ON;  



END