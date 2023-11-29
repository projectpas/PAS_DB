CREATE TABLE [dbo].[ItemMasterExportInfo] (
    [ItemMasterExportInfoId]      BIGINT          IDENTITY (1, 1) NOT NULL,
    [ItemMasterId]                BIGINT          NOT NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [ExportECCN]                  VARCHAR (200)   NOT NULL,
    [ITARNumber]                  VARCHAR (200)   NULL,
    [ExportCountryId]             SMALLINT        NULL,
    [ExportValue]                 DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfo_ExportValue] DEFAULT ((0)) NOT NULL,
    [ExportCurrencyId]            INT             NULL,
    [ExportWeight]                DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfo_ExportWeight] DEFAULT ((0)) NULL,
    [ExportWeightUnit]            VARCHAR (50)    NULL,
    [ExportUomId]                 BIGINT          NULL,
    [ExportSizeLength]            DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfo_ExportSizeLength] DEFAULT ((0)) NULL,
    [ExportSizeHeight]            DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfo_ExportSizeHeight] DEFAULT ((0)) NULL,
    [ExportSizeWidth]             DECIMAL (18, 2) CONSTRAINT [DF_ItemMasterExportInfo_ExportSizeWidth] DEFAULT ((0)) NULL,
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
    CONSTRAINT [PK_ItemMasterExportInfo] PRIMARY KEY CLUSTERED ([ItemMasterExportInfoId] ASC),
    CONSTRAINT [FK_ItemMasterExportInfo_Currency] FOREIGN KEY ([ExportCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_ItemMasterExportInfo_ExportClassification] FOREIGN KEY ([ExportClassificationId]) REFERENCES [dbo].[ExportClassification] ([ExportClassificationId]),
    CONSTRAINT [FK_ItemMasterExportInfo_MasterCompanyId] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);




GO












CREATE TRIGGER [dbo].[Trg_ItemMasterExportInfoAudit]

   ON  [dbo].[ItemMasterExportInfo]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO [dbo].[ItemMasterExportInfoAudit]

SELECT * FROM INSERTED



SET NOCOUNT ON;



END