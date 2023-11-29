﻿CREATE TABLE [dbo].[ItemMasterCapesAudit] (
    [AuditItemMasterCapesId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ItemMasterCapesId]      BIGINT         NOT NULL,
    [ItemMasterId]           BIGINT         NOT NULL,
    [CapabilityTypeId]       INT            NOT NULL,
    [ManagementStructureId]  BIGINT         NOT NULL,
    [IsVerified]             BIT            NULL,
    [VerifiedById]           BIGINT         NULL,
    [VerifiedDate]           DATETIME2 (7)  NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  NOT NULL,
    [IsActive]               BIT            NOT NULL,
    [IsDeleted]              BIT            NOT NULL,
    [AddedDate]              DATETIME2 (7)  NULL,
    [PartNumber]             VARCHAR (250)  NULL,
    [PartDescription]        NVARCHAR (MAX) NULL,
    [CapabilityType]         VARCHAR (250)  NULL,
    [VerifiedBy]             VARCHAR (250)  NULL,
    [Level1]                 VARCHAR (200)  NULL,
    [Level2]                 VARCHAR (200)  NULL,
    [Level3]                 VARCHAR (200)  NULL,
    [Level4]                 VARCHAR (200)  NULL,
    CONSTRAINT [PK_ItemMasterCapesAudit] PRIMARY KEY CLUSTERED ([AuditItemMasterCapesId] ASC)
);



