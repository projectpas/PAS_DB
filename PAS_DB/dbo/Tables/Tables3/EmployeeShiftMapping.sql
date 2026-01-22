CREATE TABLE [dbo].[EmployeeShiftMapping] (
    [EmployeeShiftMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]             BIGINT        NOT NULL,
    [ShiftId]                BIGINT        NOT NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_EmployeeShiftMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_EmployeeShiftMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [EmployeeShiftMapping_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [EmployeeShiftMapping_DC_Deleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeShiftMapping] PRIMARY KEY CLUSTERED ([EmployeeShiftMappingId] ASC),
    CONSTRAINT [FK_EmployeeShiftMapping_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_EmployeeShiftMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_EmployeeShiftMapping_ShiftId] FOREIGN KEY ([ShiftId]) REFERENCES [dbo].[Shift] ([ShiftId])
);


GO








CREATE TRIGGER [dbo].[Trg_EmployeeShiftMappingAudit]

   ON  [dbo].[EmployeeShiftMapping]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



	INSERT INTO [dbo].[EmployeeShiftMappingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END