CREATE TABLE [dbo].[ItemMasterAircraftMappingAudit] (
    [AuditItemMasterAircraftMappingId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMasterAircraftMappingId]      BIGINT         NOT NULL,
    [ItemMasterId]                     BIGINT         NOT NULL,
    [AircraftTypeId]                   INT            NOT NULL,
    [AircraftModelId]                  BIGINT         NULL,
    [DashNumberId]                     BIGINT         NULL,
    [PartNumber]                       VARCHAR (50)   NOT NULL,
    [DashNumber]                       VARCHAR (250)  NOT NULL,
    [AircraftType]                     VARCHAR (250)  NOT NULL,
    [AircraftModel]                    VARCHAR (250)  NOT NULL,
    [Memo]                             NVARCHAR (MAX) NULL,
    [MasterCompanyId]                  INT            NOT NULL,
    [CreatedBy]                        VARCHAR (256)  NOT NULL,
    [UpdatedBy]                        VARCHAR (256)  NOT NULL,
    [CreatedDate]                      DATETIME2 (7)  NULL,
    [UpdatedDate]                      DATETIME2 (7)  NULL,
    [IsActive]                         BIT            NOT NULL,
    [IsDeleted]                        BIT            NOT NULL,
    CONSTRAINT [PK_ItemMasterAircraftMappingAudit] PRIMARY KEY CLUSTERED ([AuditItemMasterAircraftMappingId] ASC)
);

