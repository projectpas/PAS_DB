CREATE TABLE [dbo].[CustomerAircraftMapping] (
    [CustomerAircraftMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerId]                BIGINT        NOT NULL,
    [AircraftTypeId]            INT           NOT NULL,
    [AircraftModelId]           BIGINT        NULL,
    [DashNumberId]              BIGINT        NULL,
    [AircraftType]              VARCHAR (250) NOT NULL,
    [AircraftModel]             VARCHAR (250) NOT NULL,
    [DashNumber]                VARCHAR (250) NOT NULL,
    [Inventory]                 INT           CONSTRAINT [DF_CustomerAircraftMapping_Inventory] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) CONSTRAINT [DF_CustomerAircraftMapping_CreatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) CONSTRAINT [DF_CustomerAircraftMapping_UpdatedDate] DEFAULT (sysdatetime()) NOT NULL,
    [IsActive]                  BIT           CONSTRAINT [D_CAM_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT           CONSTRAINT [CustomerAircraftMapping_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_CACMapping] PRIMARY KEY CLUSTERED ([CustomerAircraftMappingId] ASC),
    CONSTRAINT [FK_CustomerAircraftMapping_AircraftDashNumber] FOREIGN KEY ([DashNumberId]) REFERENCES [dbo].[AircraftDashNumber] ([DashNumberId]),
    CONSTRAINT [FK_CustomerAircraftMapping_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_CustomerAircraftMapping_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_CustomerAircraftMapping_Customer] FOREIGN KEY ([CustomerId]) REFERENCES [dbo].[Customer] ([CustomerId]),
    CONSTRAINT [FK_CustomerAircraftMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [CustomerAircraftMappingConstrain] UNIQUE NONCLUSTERED ([CustomerId] ASC, [AircraftTypeId] ASC, [AircraftModelId] ASC, [DashNumberId] ASC, [MasterCompanyId] ASC)
);


GO


------------------------

CREATE TRIGGER [dbo].[Trg_CustomerAircraftMappingAudit]

   ON  [dbo].[CustomerAircraftMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[CustomerAircraftMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END