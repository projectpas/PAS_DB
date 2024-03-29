﻿CREATE TABLE [dbo].[AssetDepreciationHistory] (
    [ID]                    BIGINT          IDENTITY (1, 1) NOT NULL,
    [SerialNo]              VARCHAR (20)    NOT NULL,
    [StklineNumber]         VARCHAR (50)    NOT NULL,
    [InServiceDate]         DATETIME        NULL,
    [DepriciableStatus]     VARCHAR (20)    NULL,
    [CURRENCY]              VARCHAR (10)    NULL,
    [DepriciableLife]       INT             NULL,
    [DepreciationMethod]    VARCHAR (30)    NULL,
    [DepreciationFrequency] VARCHAR (20)    NULL,
    [AssetId]               VARCHAR (20)    NULL,
    [AssetInventoryId]      BIGINT          NULL,
    [InstalledCost]         DECIMAL (18, 2) NULL,
    [DepreciationAmount]    DECIMAL (18, 2) NULL,
    [AccumlatedDepr]        DECIMAL (18, 2) NULL,
    [NetBookValue]          DECIMAL (18, 2) NULL,
    [NBVAfterDepreciation]  DECIMAL (18, 2) NULL,
    [LastDeprRunPeriod]     VARCHAR (30)    NULL,
    [AccountingCalenderId]  BIGINT          NULL,
    [MasterCompanyId]       BIGINT          NOT NULL,
    [CreatedBy]             VARCHAR (30)    NOT NULL,
    [CreatedDate]           DATETIME        NOT NULL,
    [UpdatedBy]             VARCHAR (30)    NOT NULL,
    [UpdatedDate]           DATETIME        NOT NULL,
    [IsActive]              BIT             CONSTRAINT [AssetDepreciationHistory_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDelete]              BIT             CONSTRAINT [DF_AssetDepreciationHistory_IsDeleted] DEFAULT ((0)) NOT NULL,
    [DepreciationStartDate] DATETIME        NULL,
    CONSTRAINT [PK_ID] PRIMARY KEY CLUSTERED ([ID] ASC)
);







