CREATE TABLE [dbo].[EmployeeLeaveTypeMapping] (
    [EmployeeLeaveTypeMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]                 BIGINT        NOT NULL,
    [EmployeeLeaveTypeId]        INT           NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) CONSTRAINT [DF_EmployeeLeaveTypeMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) CONSTRAINT [DF_EmployeeLeaveTypeMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                   BIT           CONSTRAINT [EmployeeLeaveTypeMapping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT           CONSTRAINT [EmployeeLeaveTypeMapping_DC_Deleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeLeaveTypeMapping] PRIMARY KEY CLUSTERED ([EmployeeLeaveTypeMappingId] ASC),
    CONSTRAINT [FK_EmployeeLeaveTypeMapping_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_EmployeeLeaveTypeMapping_EmployeeLeaveType] FOREIGN KEY ([EmployeeLeaveTypeId]) REFERENCES [dbo].[EmployeeLeaveType] ([EmployeeLeaveTypeId]),
    CONSTRAINT [FK_EmployeeLeaveTypeMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_EmployeeLeaveTypeMappingAudit]

   ON  [dbo].[EmployeeLeaveTypeMapping]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



	INSERT INTO [dbo].[EmployeeLeaveTypeMappingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END