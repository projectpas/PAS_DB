﻿CREATE TABLE [dbo].[SalesOrderSettingsAudit] (
    [SalesOrderSettingAuditId]   BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesOrderSettingId]        BIGINT        NOT NULL,
    [TypeId]                     INT           NOT NULL,
    [Prefix]                     VARCHAR (20)  NULL,
    [Sufix]                      VARCHAR (20)  NULL,
    [StartCode]                  BIGINT        NULL,
    [CurrentNumber]              BIGINT        NOT NULL,
    [DefaultStatusId]            INT           NOT NULL,
    [DefaultPriorityId]          BIGINT        NOT NULL,
    [SOListViewId]               INT           NOT NULL,
    [SOListStatusId]             INT           NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    [IsApprovalRule]             BIT           NULL,
    [EffectiveDate]              DATETIME2 (7) NULL,
    [AutoReserve]                BIT           NULL,
    [AllowInvoiceBeforeShipping] BIT           NULL,
    CONSTRAINT [PK_SalesOrderSettingsAudit] PRIMARY KEY CLUSTERED ([SalesOrderSettingAuditId] ASC),
    CONSTRAINT [FK_SalesOrderSettingsAudit_SalesOrderSettings] FOREIGN KEY ([SalesOrderSettingId]) REFERENCES [dbo].[SalesOrderSettings] ([SalesOrderSettingId])
);





