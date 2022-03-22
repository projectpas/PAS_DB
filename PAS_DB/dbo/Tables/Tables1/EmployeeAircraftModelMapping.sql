CREATE TABLE [dbo].[EmployeeAircraftModelMapping] (
    [EmployeeAircraftModelMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]                     BIGINT        NOT NULL,
    [AircraftManufacturerId]         INT           NOT NULL,
    [AircraftModelId]                BIGINT        NOT NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) CONSTRAINT [DF_EmployeeAircraftModelMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) CONSTRAINT [DF_EmployeeAircraftModelMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                       BIT           CONSTRAINT [DF_EmployeeAircraftModelMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT           CONSTRAINT [DF_EmployeeAircraftModelMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeAircraftModelMapping] PRIMARY KEY CLUSTERED ([EmployeeAircraftModelMappingId] ASC),
    CONSTRAINT [FK_EmployeeAircraftModelMapping_AircraftManufacturer] FOREIGN KEY ([AircraftManufacturerId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_EmployeeAircraftModelMapping_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_EmployeeAircraftModelMapping_Employee] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_EmployeeAircraftModelMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO






CREATE TRIGGER [dbo].[Trg_EmployeeAircraftModelMappingAudit]

   ON  [dbo].[EmployeeAircraftModelMapping]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO [dbo].[EmployeeAircraftModelMappingAudit]

	SELECT * FROM INSERTED;

	SET NOCOUNT ON;

END