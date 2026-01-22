CREATE TABLE [dbo].[Capability] (
    [CapabilityId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [CapabilityTypeId]      INT            NULL,
    [Description]           VARCHAR (100)  NULL,
    [AircraftTypeId]        INT            NULL,
    [AircraftModelId]       BIGINT         NULL,
    [AircraftManufacturer]  VARCHAR (50)   NULL,
    [ItemMasterId]          BIGINT         NULL,
    [EntryDate]             DATETIME2 (7)  NULL,
    [IsCMMExist]            BIT            NULL,
    [IsVerified]            BIT            NULL,
    [VerifiedBy]            VARCHAR (256)  NULL,
    [DateVerified]          DATETIME2 (7)  NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [ComponentDescription]  VARCHAR (30)   NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NULL,
    [UpdatedBy]             VARCHAR (256)  NULL,
    [CreatedDate]           DATETIME2 (7)  CONSTRAINT [DF_Capability_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  CONSTRAINT [DF_Capability_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]              BIT            CONSTRAINT [DF_Capability_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]             BIT            CONSTRAINT [DF_Capability_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ATAChapterId]          BIGINT         NULL,
    [ManufacturerId]        BIGINT         NULL,
    [ManagementStructureId] BIGINT         NULL,
    [AssetRecordId]         BIGINT         NULL,
    [AircraftDashNumberId]  INT            NULL,
    CONSTRAINT [PK_Capability] PRIMARY KEY CLUSTERED ([CapabilityId] ASC),
    CONSTRAINT [FK_Capability_AircraftModel] FOREIGN KEY ([AircraftModelId]) REFERENCES [dbo].[AircraftModel] ([AircraftModelId]),
    CONSTRAINT [FK_Capability_AircraftType] FOREIGN KEY ([AircraftTypeId]) REFERENCES [dbo].[AircraftType] ([AircraftTypeId]),
    CONSTRAINT [FK_Capability_CapabilityType] FOREIGN KEY ([CapabilityTypeId]) REFERENCES [dbo].[CapabilityType] ([CapabilityTypeId]),
    CONSTRAINT [FK_Capability_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Capability_Part] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId])
);


GO




CREATE TRIGGER [dbo].[Trg_CapabilityAudit]

   ON  [dbo].[Capability]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO CapabilityAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END