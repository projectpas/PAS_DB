CREATE TABLE [dbo].[EmployeeStation] (
    [EmployeeStationId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [StationName]       VARCHAR (100)  NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [EmployeeStation_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [EmployeeStation_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [IsActive]          BIT            CONSTRAINT [EmployeeStation_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [EmployeeStation_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Description]       VARCHAR (MAX)  NULL,
    CONSTRAINT [PK_EmployeeStation] PRIMARY KEY CLUSTERED ([EmployeeStationId] ASC),
    CONSTRAINT [FK_EmployeeStation_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_EmployeeStation] UNIQUE NONCLUSTERED ([StationName] ASC, [MasterCompanyId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_EmployeeStationAudit]

   ON  [dbo].[EmployeeStation]

   AFTER INSERT,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[EmployeeStationAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END
GO




CREATE TRIGGER [dbo].[Trg_EmployeeStationAuditDelete]

   ON  [dbo].[EmployeeStation]

   AFTER DELETE

AS 

BEGIN

	INSERT INTO [dbo].[EmployeeStationAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END