﻿CREATE TABLE [dbo].[ExchangeSalesOrderSettingsAudit] (
    [AuditExchangeSalesOrderSettingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderSettingId]      BIGINT        NOT NULL,
    [TypeId]                           INT           NOT NULL,
    [ValidDays]                        INT           NULL,
    [Prefix]                           VARCHAR (20)  NULL,
    [Sufix]                            VARCHAR (20)  NULL,
    [StartCode]                        BIGINT        NULL,
    [CurrentNumber]                    BIGINT        NOT NULL,
    [DefaultStatusId]                  INT           NOT NULL,
    [DefaultPriorityId]                BIGINT        NOT NULL,
    [SOListViewId]                     INT           NOT NULL,
    [SOListStatusId]                   INT           NOT NULL,
    [COGS]                             INT           NOT NULL,
    [DaysForCoreReturn]                INT           NOT NULL,
    [MasterCompanyId]                  INT           NOT NULL,
    [CreatedBy]                        VARCHAR (256) NOT NULL,
    [UpdatedBy]                        VARCHAR (256) NOT NULL,
    [CreatedDate]                      DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderSettingsAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                      DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderSettingsAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                         BIT           CONSTRAINT [DF_ExchangeSalesOrderSettingsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                        BIT           CONSTRAINT [DF_ExchangeSalesOrderSettingsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsApprovalRule]                   BIT           NULL,
    [EffectiveDate]                    DATETIME2 (7) NULL,
    [FeesBillingIntervalDays]          INT           NULL,
    [ExpectedConditionId]              BIGINT        NULL,
    CONSTRAINT [PK_ExchangeSalesOrderSettingsAudit] PRIMARY KEY CLUSTERED ([AuditExchangeSalesOrderSettingId] ASC)
);



