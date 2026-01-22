CREATE TABLE [dbo].[VendorCapabilityAircraftAudit] (
    [AuditVendorCapabilityAirCraftId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorCapabilityAircraftId]      BIGINT         NOT NULL,
    [VendorCapabilityId]              BIGINT         NOT NULL,
    [AircraftTypeId]                  INT            NOT NULL,
    [AircraftModelId]                 INT            NULL,
    [DashNumberId]                    BIGINT         NULL,
    [MasterCompanyId]                 INT            NOT NULL,
    [Memo]                            NVARCHAR (MAX) NULL,
    [CreatedBy]                       VARCHAR (256)  NOT NULL,
    [UpdatedBy]                       VARCHAR (256)  NOT NULL,
    [CreatedDate]                     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]                     DATETIME2 (7)  NOT NULL,
    [IsActive]                        BIT            NOT NULL,
    [IsDeleted]                       BIT            NOT NULL,
    CONSTRAINT [PK_VendorCapabilityAircraftAudit] PRIMARY KEY CLUSTERED ([AuditVendorCapabilityAirCraftId] ASC),
    CONSTRAINT [FK_VendorCapabilityAircraftAudit_VendorCapabilityAircraft] FOREIGN KEY ([VendorCapabilityAircraftId]) REFERENCES [dbo].[VendorCapabilityAircraft] ([VendorCapabilityAircraftId])
);

