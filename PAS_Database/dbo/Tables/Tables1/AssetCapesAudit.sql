CREATE TABLE [dbo].[AssetCapesAudit] (
    [AssetCapesAuditId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [AssetCapesId]         BIGINT        NOT NULL,
    [AssetRecordId]        BIGINT        NULL,
    [CapabilityId]         BIGINT        NULL,
    [MasterCompanyId]      INT           NULL,
    [CreatedBy]            VARCHAR (256) NULL,
    [UpdatedBy]            VARCHAR (256) NULL,
    [CreatedDate]          DATETIME2 (7) NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NULL,
    [IsDeleted]            BIT           CONSTRAINT [AssetCapesAudit_DC_Delete] DEFAULT ((0)) NULL,
    [AircraftTypeId]       INT           NULL,
    [AircraftModelId]      BIGINT        NULL,
    [AircraftDashNumberId] BIGINT        NULL,
    [ItemMasterId]         BIGINT        NULL,
    CONSTRAINT [PK__AssetCap__240B9377CC77482B] PRIMARY KEY CLUSTERED ([AssetCapesAuditId] ASC),
    CONSTRAINT [FK_AssetCapesAudit_AssetCapes] FOREIGN KEY ([AssetCapesId]) REFERENCES [dbo].[AssetCapes] ([AssetCapesId])
);

