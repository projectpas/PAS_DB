﻿CREATE TABLE [dbo].[ItemMasterExportInfoAudit] (
    [ItemMasterExportInfoAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemMasterExportInfoId]      BIGINT          NOT NULL,
    [ItemMasterId]                BIGINT          NOT NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [ExportECCN]                  VARCHAR (200)   NOT NULL,
    [ITARNumber]                  VARCHAR (200)   NULL,
    [ExportCountryId]             SMALLINT        NULL,
    [ExportValue]                 DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfoAudit_ExportValue] DEFAULT ((0)) NOT NULL,
    [ExportCurrencyId]            INT             NULL,
    [ExportWeight]                DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfoAudit_ExportWeight] DEFAULT ((0)) NULL,
    [ExportWeightUnit]            VARCHAR (50)    NULL,
    [ExportUomId]                 BIGINT          NULL,
    [ExportSizeLength]            DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfoAudit_ExportSizeLength] DEFAULT ((0)) NULL,
    [ExportSizeHeight]            DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfoAudit_ExportSizeHeight] DEFAULT ((0)) NULL,
    [ExportSizeWidth]             DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfoAudit_ExportSizeWidth] DEFAULT ((0)) NULL,
    [ExportSizeUnitOfMeasureId]   BIGINT          NULL,
    [ExportClassificationId]      TINYINT         NULL,
    [CreatedBy]                   VARCHAR (50)    NULL,
    [CreatedDate]                 DATETIME2 (7)   NOT NULL,
    [UpdatedBy]                   VARCHAR (50)    NULL,
    [UpdatedDate]                 DATETIME2 (7)   NOT NULL,
    [IsActive]                    BIT             NOT NULL,
    [IsDeleted]                   BIT             NOT NULL,
    [ExportCountryName]           VARCHAR (200)   NULL,
    [ExportCurrencyName]          VARCHAR (200)   NULL,
    [ExportWeightUnitName]        VARCHAR (200)   NULL,
    [ExportUomName]               VARCHAR (200)   NULL,
    [ExportSizeUnitOfMeasureName] VARCHAR (200)   NULL,
    [ExportClassificationIdName]  VARCHAR (200)   NULL,
    [IsIATR]                      BIT             DEFAULT ((0)) NOT NULL,
    [IsExportLicense]             BIT             DEFAULT ((0)) NOT NULL,
    [ScheduleB]                   VARCHAR (15)    NULL,
    [HSCode]                      VARCHAR (15)    NULL,
    [HTSCode]                     VARCHAR (15)    NULL,
    [ECCNDeterminationSourceID]   INT             DEFAULT ((0)) NOT NULL,
    [ECCNDeterminationSourceName] VARCHAR (100)   NULL,
    CONSTRAINT [PK_ItemMasterExportInfoAudit] PRIMARY KEY CLUSTERED ([ItemMasterExportInfoAuditId] ASC)
);



