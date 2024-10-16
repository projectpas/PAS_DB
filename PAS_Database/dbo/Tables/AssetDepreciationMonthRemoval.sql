﻿CREATE TABLE [dbo].[AssetDepreciationMonthRemoval] (
    [AssetDepreciationMonthRemovalId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AssetId]                         VARCHAR (20)    NULL,
    [AssetInventoryId]                BIGINT          NULL,
    [DepreciableStatus]               VARCHAR (20)    NULL,
    [Currency]                        VARCHAR (10)    NULL,
    [AccountingCalenderId]            BIGINT          NULL,
    [DepreciationLife]                INT             NULL,
    [DepreciationMethod]              VARCHAR (30)    NULL,
    [DepreciationFrequency]           VARCHAR (20)    NULL,
    [DepreciationStartDate]           DATETIME        NULL,
    [InstalledCost]                   DECIMAL (18, 2) NULL,
    [DepreciationAmount]              DECIMAL (18, 2) NULL,
    [AccumlatedDepr]                  DECIMAL (18, 2) NULL,
    [NetBookValue]                    DECIMAL (18, 2) NULL,
    [NBVAfterDepreciation]            DECIMAL (18, 2) NULL,
    [LastDeprRunPeriod]               VARCHAR (30)    NULL,
    [MasterCompanyId]                 BIGINT          NOT NULL,
    [IsActive]                        BIT             CONSTRAINT [DF_AssetDepreciationMonthRemoval_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                       BIT             CONSTRAINT [DF_AssetDepreciationMonthRemoval_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CreatedBy]                       VARCHAR (30)    NOT NULL,
    [CreatedDate]                     DATETIME        NOT NULL,
    [UpdatedBy]                       VARCHAR (30)    NOT NULL,
    [UpdatedDate]                     DATETIME        NOT NULL,
    CONSTRAINT [PK_AssetDepreciationMonthRemoval] PRIMARY KEY CLUSTERED ([AssetDepreciationMonthRemovalId] ASC)
);

