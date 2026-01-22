CREATE TABLE [dbo].[VendorCapabilityAircraft] (
    [VendorCapabilityAircraftId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorCapabilityId]         BIGINT         NOT NULL,
    [AircraftTypeId]             INT            NOT NULL,
    [AircraftModelId]            INT            NOT NULL,
    [DashNumberId]               BIGINT         NOT NULL,
    [MasterCompanyId]            INT            NOT NULL,
    [Memo]                       NVARCHAR (MAX) NULL,
    [CreatedBy]                  VARCHAR (256)  NOT NULL,
    [UpdatedBy]                  VARCHAR (256)  NOT NULL,
    [CreatedDate]                DATETIME2 (7)  CONSTRAINT [VendorCapabilityAircraft_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                DATETIME2 (7)  CONSTRAINT [VendorCapabilityAircraft_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                   BIT            CONSTRAINT [VendorCapabilityAircraft_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                  BIT            CONSTRAINT [VendorCapabilityAircraft_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorCapabilityAircraft] PRIMARY KEY CLUSTERED ([VendorCapabilityAircraftId] ASC),
    CONSTRAINT [FK_VendorCapabilityAircraft_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_VendorCapabilityAircraft_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_VendorCapabilityAircraft] UNIQUE NONCLUSTERED ([VendorCapabilityId] ASC, [AircraftTypeId] ASC, [AircraftModelId] ASC, [DashNumberId] ASC, [MasterCompanyId] ASC)
);


GO


---------------------------





CREATE TRIGGER [dbo].[Trg_VendorCapabilityAircraftAudit]

   ON  [dbo].[VendorCapabilityAircraft]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[VendorCapabilityAircraftAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END