﻿CREATE TABLE [dbo].[TimeLifeDraftAudit] (
    [TimeLifeDraftCyclesAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TimeLifeDraftCyclesId]      BIGINT        NOT NULL,
    [CyclesRemaining]            VARCHAR (20)  NULL,
    [CyclesSinceNew]             VARCHAR (20)  NULL,
    [CyclesSinceOVH]             VARCHAR (20)  NULL,
    [CyclesSinceInspection]      VARCHAR (20)  NULL,
    [CyclesSinceRepair]          VARCHAR (20)  NULL,
    [TimeRemaining]              VARCHAR (20)  NULL,
    [TimeSinceNew]               VARCHAR (20)  NULL,
    [TimeSinceOVH]               VARCHAR (20)  NULL,
    [TimeSinceInspection]        VARCHAR (20)  NULL,
    [TimeSinceRepair]            VARCHAR (20)  NULL,
    [LastSinceNew]               VARCHAR (20)  NULL,
    [LastSinceOVH]               VARCHAR (20)  NULL,
    [LastSinceInspection]        VARCHAR (20)  NULL,
    [MasterCompanyId]            INT           NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [PurchaseOrderId]            BIGINT        NULL,
    [PurchaseOrderPartRecordId]  BIGINT        NULL,
    [StockLineDraftId]           BIGINT        CONSTRAINT [DF_TimeLifeDraftAudit_StockLineDraftId] DEFAULT ((0)) NOT NULL,
    [DetailsNotProvided]         BIT           CONSTRAINT [DF_TimeLifeDraftAudit_DetailsNotProvided] DEFAULT ((1)) NOT NULL,
    [RepairOrderId]              BIGINT        NULL,
    [RepairOrderPartRecordId]    BIGINT        NULL,
    [VendorRMAId]                BIGINT        NULL,
    [VendorRMADetailId]          BIGINT        NULL,
    CONSTRAINT [PK_TimeLifeDraftAudit] PRIMARY KEY CLUSTERED ([TimeLifeDraftCyclesAuditId] ASC)
);

