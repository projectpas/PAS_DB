CREATE TABLE [dbo].[EmployeeTraining] (
    [EmployeeTrainingId]     BIGINT          IDENTITY (1, 1) NOT NULL,
    [EmployeeId]             BIGINT          NOT NULL,
    [AircraftModelId]        BIGINT          NULL,
    [EmployeeTrainingTypeId] BIGINT          NOT NULL,
    [ScheduleDate]           DATETIME2 (7)   NULL,
    [CompletionDate]         DATETIME2 (7)   NULL,
    [Cost]                   NUMERIC (18, 2) NULL,
    [Duration]               INT             NULL,
    [Provider]               VARCHAR (30)    NULL,
    [IndustryCode]           VARCHAR (30)    NULL,
    [ExpirationDate]         DATETIME2 (7)   NULL,
    [MasterCompanyId]        INT             NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [EmployeeTraining_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [EmployeeTraining_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT             CONSTRAINT [EmployeeTraining_DC_IsActive] DEFAULT ((1)) NOT NULL,
    [FrequencyOfTrainingId]  BIGINT          NULL,
    [AircraftManufacturerId] INT             NULL,
    [DurationTypeId]         INT             NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_EmployeeTraining_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmployeeTraining] PRIMARY KEY CLUSTERED ([EmployeeTrainingId] ASC),
    CONSTRAINT [FK_EmployeeTraining_AircraftManufacturer] FOREIGN KEY ([AircraftManufacturerId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_EmployeeTraining_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_EmployeeTraining_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_EmployeeTraining_EmployeeTrainingType] FOREIGN KEY ([EmployeeTrainingTypeId]) REFERENCES [dbo].[EmployeeTrainingType] ([EmployeeTrainingTypeId]),
    CONSTRAINT [FK_EmployeeTraining_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_EmployeeTrainingAudit]

   ON  [dbo].[EmployeeTraining]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[EmployeeTrainingAudit]

	SELECT * FROM INSERTED

	SET NOCOUNT ON;



END