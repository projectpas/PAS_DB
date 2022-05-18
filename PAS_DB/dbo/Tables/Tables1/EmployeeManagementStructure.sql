CREATE TABLE [dbo].[EmployeeManagementStructure] (
    [EmployeeManagementId]  BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]            BIGINT        NOT NULL,
    [ManagementStructureId] BIGINT        NOT NULL,
    [MasterCompanyId]       INT           NOT NULL,
    [CreatedBy]             VARCHAR (256) NOT NULL,
    [CreatedDate]           DATETIME2 (7) CONSTRAINT [EmployeeManagementStructure_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]             VARCHAR (256) NOT NULL,
    [UpdatedDate]           DATETIME2 (7) CONSTRAINT [EmployeeManagementStructure_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT           CONSTRAINT [DF__EmployeeM__IsAct__2630A1B7] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT           CONSTRAINT [DF__EmployeeM__IsDel__2724C5F0] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK__Employee__2C12D4026186959E] PRIMARY KEY CLUSTERED ([EmployeeManagementId] ASC),
    CONSTRAINT [FK_EmployeeManagementStructure_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_EmployeeManagementStructure_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO








CREATE TRIGGER [dbo].[Trg_EmployeeManagementStructureAudit]

   ON  [dbo].[EmployeeManagementStructure]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



	INSERT INTO [dbo].[EmployeeManagementStructureAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END