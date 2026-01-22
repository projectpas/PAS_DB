CREATE TABLE [dbo].[AircraftDashNumber] (
    [DashNumberId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [AircraftTypeId]  INT            NOT NULL,
    [AircraftModelId] BIGINT         NOT NULL,
    [DashNumber]      VARCHAR (250)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [[AircraftDashNumber_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [AircraftDashNumber_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_AircraftDashNumber_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_AircraftDashNumber_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AircraftDashNumber] PRIMARY KEY CLUSTERED ([DashNumberId] ASC),
    CONSTRAINT [FK_AircraftDashNumber_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_DashNumber_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_DashNumber_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [Unique_AircraftDashNumber] UNIQUE NONCLUSTERED ([AircraftTypeId] ASC, [AircraftModelId] ASC, [DashNumber] ASC, [MasterCompanyId] ASC)
);


GO






-- =============================================

CREATE TRIGGER [dbo].[Trg_AircraftDashNumberAudit]

   ON  [dbo].[AircraftDashNumber]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	DECLARE @AircraftTypeId BIGINT ,@AircraftModelId BIGINT

	DECLARE @AircraftModel VARCHAR(256),@AircraftType VARCHAR(256) 

	

	SELECT @AircraftTypeId=AircraftTypeId,@AircraftModelId=AircraftModelId FROM INSERTED



	SELECT  @AircraftType = Description FROM AircraftType WHERE AircraftTypeId=@AircraftTypeId

	SELECT  @AircraftModel = ModelName FROM AircraftModel WHERE AircraftModelId=@AircraftModelId



	INSERT INTO AircraftDashNumberAudit

	SELECT *,@AircraftType,@AircraftModel FROM INSERTED



	SET NOCOUNT ON;



END