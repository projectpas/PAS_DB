﻿CREATE TABLE [dbo].[CapabilityAudit] (
    [CapabilityId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [CapabilityAuditId]     BIGINT         NOT NULL,
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
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [ATAChapterId]          BIGINT         NULL,
    [ManufacturerId]        BIGINT         NULL,
    [ManagementStructureId] BIGINT         NULL,
    [AssetRecordId]         BIGINT         NULL,
    [AircraftDashNumberId]  INT            NULL,
    CONSTRAINT [PK_CapabilityAudit] PRIMARY KEY CLUSTERED ([CapabilityAuditId] ASC)
);

