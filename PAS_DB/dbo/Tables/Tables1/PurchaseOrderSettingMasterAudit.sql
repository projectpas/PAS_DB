﻿CREATE TABLE [dbo].[PurchaseOrderSettingMasterAudit] (
    [PurchaseOrderSettingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PurchaseOrderSettingId]      BIGINT        NOT NULL,
    [IsResale]                    BIT           NOT NULL,
    [IsDeferredReceiver]          BIT           NOT NULL,
    [IsEnforceApproval]           BIT           NOT NULL,
    [MasterCompanyId]             INT           NOT NULL,
    [CreatedBy]                   VARCHAR (256) NOT NULL,
    [UpdatedBy]                   VARCHAR (256) NOT NULL,
    [CreatedDate]                 DATETIME2 (7) NOT NULL,
    [UpdatedDate]                 DATETIME2 (7) NOT NULL,
    [IsActive]                    BIT           NOT NULL,
    [IsDeleted]                   BIT           NOT NULL,
    [Effectivedate]               DATETIME2 (7) NULL,
    CONSTRAINT [PK_PurchaseOrderSettingMasterAudit] PRIMARY KEY CLUSTERED ([PurchaseOrderSettingAuditId] ASC)
);

