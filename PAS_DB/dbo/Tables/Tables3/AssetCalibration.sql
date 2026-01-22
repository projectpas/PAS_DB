CREATE TABLE [dbo].[AssetCalibration] (
    [AssetCalibrationId]                BIGINT          IDENTITY (1, 1) NOT NULL,
    [AssetRecordId]                     BIGINT          NOT NULL,
    [CalibrationRequired]               BIT             CONSTRAINT [AssetCalibration_CalibrationRequired] DEFAULT ((0)) NULL,
    [CalibrationFrequencyMonths]        INT             NULL,
    [CalibrationFrequencyDays]          BIGINT          NULL,
    [CalibrationDefaultVendorId]        BIGINT          NULL,
    [CalibrationDefaultCost]            DECIMAL (18, 2) NULL,
    [CalibrationCurrencyId]             INT             NULL,
    [CalibrationGlAccountId]            BIGINT          NULL,
    [CalibrationMemo]                   NVARCHAR (MAX)  NULL,
    [AssetCalibrationMin]               VARCHAR (30)    NULL,
    [AssetCalibrationMinTolerance]      VARCHAR (30)    NULL,
    [AssetCalibratonMax]                VARCHAR (30)    NULL,
    [AssetCalibrationMaxTolerance]      VARCHAR (30)    NULL,
    [AssetCalibrationExpected]          VARCHAR (30)    NULL,
    [AssetCalibrationExpectedTolerance] VARCHAR (30)    NULL,
    [AssetCalibrationMemo]              NVARCHAR (MAX)  NULL,
    [CertificationRequired]             BIT             CONSTRAINT [AssetCalibration_CertificationRequired] DEFAULT ((0)) NULL,
    [CertificationFrequencyMonths]      INT             NULL,
    [CertificationFrequencyDays]        BIGINT          NULL,
    [CertificationDefaultVendorId]      BIGINT          NULL,
    [CertificationDefaultCost]          DECIMAL (18, 2) NULL,
    [CertificationCurrencyId]           INT             NULL,
    [CertificationGlAccountId]          BIGINT          NULL,
    [CertificationMemo]                 NVARCHAR (MAX)  NULL,
    [InspectionRequired]                BIT             CONSTRAINT [AssetCalibration_InspectionRequired] DEFAULT ((0)) NULL,
    [InspectionFrequencyMonths]         INT             NULL,
    [InspectionFrequencyDays]           BIGINT          NULL,
    [InspectionDefaultCost]             DECIMAL (18, 2) NULL,
    [InspectionCurrencyId]              INT             NULL,
    [InspectionDefaultVendorId]         BIGINT          NULL,
    [InspectionGlaAccountId]            BIGINT          NULL,
    [InspectionMemo]                    NVARCHAR (MAX)  NULL,
    [VerificationRequired]              BIT             CONSTRAINT [AssetCalibration_VerificationRequired] DEFAULT ((0)) NULL,
    [VerificationFrequencyMonths]       INT             NULL,
    [VerificationFrequencyDays]         BIGINT          NULL,
    [VerificationDefaultCost]           DECIMAL (18, 2) NULL,
    [VerificationCurrencyId]            INT             NULL,
    [VerificationDefaultVendorId]       BIGINT          NULL,
    [VerificationGlAccountId]           BIGINT          NULL,
    [VerificationMemo]                  NVARCHAR (MAX)  NULL,
    [MasterCompanyId]                   INT             NOT NULL,
    [IsDeleted]                         BIT             CONSTRAINT [AssetCalibration_DC_Delete] DEFAULT ((0)) NOT NULL,
    [IsActive]                          BIT             CONSTRAINT [AssetCalibration_DC_Active] DEFAULT ((1)) NOT NULL,
    [CreatedBy]                         VARCHAR (256)   NOT NULL,
    [UpdatedBy]                         VARCHAR (256)   NOT NULL,
    [CreatedDate]                       DATETIME2 (7)   CONSTRAINT [AssetCalibration_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                       DATETIME2 (7)   CONSTRAINT [AssetCalibration_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [CalibrationProvider]               VARCHAR (10)    NULL,
    [CertificationProvider]             VARCHAR (10)    NULL,
    [InspectionProvider]                VARCHAR (10)    NULL,
    [VerificationProvider]              VARCHAR (10)    NULL,
    CONSTRAINT [PK_AssetCalibration] PRIMARY KEY CLUSTERED ([AssetCalibrationId] ASC),
    CONSTRAINT [FK_AssetCalibration_AssetRecordId] FOREIGN KEY ([AssetRecordId]) REFERENCES [dbo].[Asset] ([AssetRecordId]),
    CONSTRAINT [FK_AssetCalibration_CalibrationCurrencyId] FOREIGN KEY ([CalibrationCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_AssetCalibration_CalibrationDefaultVendorId] FOREIGN KEY ([CalibrationDefaultVendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_AssetCalibration_CalibrationGlAccountId] FOREIGN KEY ([CalibrationGlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetCalibration_CertificationCurrencyId] FOREIGN KEY ([CertificationCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_AssetCalibration_CertificationDefaultVendorId] FOREIGN KEY ([CertificationDefaultVendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_AssetCalibration_CertificationGlAccountId] FOREIGN KEY ([CertificationGlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetCalibration_InspectionCurrencyId] FOREIGN KEY ([InspectionCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_AssetCalibration_InspectionDefaultVendorId] FOREIGN KEY ([InspectionDefaultVendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_AssetCalibration_InspectionGlaAccountId] FOREIGN KEY ([InspectionGlaAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId]),
    CONSTRAINT [FK_AssetCalibration_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_AssetCalibration_VerificationCurrencyId] FOREIGN KEY ([VerificationCurrencyId]) REFERENCES [dbo].[Currency] ([CurrencyId]),
    CONSTRAINT [FK_AssetCalibration_VerificationDefaultVendorId] FOREIGN KEY ([VerificationDefaultVendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [FK_AssetCalibration_VerificationGlAccountId] FOREIGN KEY ([VerificationGlAccountId]) REFERENCES [dbo].[GLAccount] ([GLAccountId])
);


GO




Create Trigger [dbo].[trg_AssetCalibration]

on [dbo].[AssetCalibration] 

 AFTER INSERT,UPDATE 

As  

Begin  



SET NOCOUNT ON

INSERT INTO AssetCalibrationAudit (AssetCalibrationId,AssetRecordId,CalibrationRequired,CertificationRequired,InspectionRequired,VerificationRequired,

AssetCalibrationMin,AssetCalibrationMinTolerance,AssetCalibratonMax,AssetCalibrationMaxTolerance,AssetCalibrationExpected,AssetCalibrationExpectedTolerance,AssetCalibrationMemo,

MasterCompanyId,IsDeleted,IsActive,CalibrationDefaultVendorId,CertificationDefaultVendorId,InspectionDefaultVendorId,VerificationDefaultVendorId,CertificationFrequencyMonths,

CertificationFrequencyDays,CertificationDefaultCost,CertificationGlAccountId,CertificationMemo,InspectionMemo,InspectionGlaAccountId,InspectionDefaultCost,

InspectionFrequencyMonths,InspectionFrequencyDays,VerificationFrequencyDays,VerificationFrequencyMonths,VerificationDefaultCost,

CalibrationDefaultCost,CalibrationFrequencyMonths,CalibrationFrequencyDays,CalibrationGlAccountId,CalibrationMemo,VerificationMemo,VerificationGlAccountId,

CalibrationCurrencyId,CertificationCurrencyId,InspectionCurrencyId,VerificationCurrencyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate)

SELECT AssetCalibrationId, AssetRecordId,CalibrationRequired,CertificationRequired,InspectionRequired,

VerificationRequired,AssetCalibrationMin,AssetCalibrationMinTolerance,AssetCalibratonMax,

AssetCalibrationMaxTolerance,AssetCalibrationExpected,AssetCalibrationExpectedTolerance,AssetCalibrationMemo,MasterCompanyId,

IsDeleted,IsActive,CalibrationDefaultVendorId,CertificationDefaultVendorId,InspectionDefaultVendorId,VerificationDefaultVendorId,CertificationFrequencyMonths,

CertificationFrequencyDays,CertificationDefaultCost,CertificationGlAccountId,CertificationMemo,InspectionMemo,InspectionGlaAccountId,InspectionDefaultCost,

InspectionFrequencyMonths,InspectionFrequencyDays,VerificationFrequencyDays,VerificationFrequencyMonths,VerificationDefaultCost,

CalibrationDefaultCost,CalibrationFrequencyMonths,CalibrationFrequencyDays,CalibrationGlAccountId,CalibrationMemo,VerificationMemo,VerificationGlAccountId,

CalibrationCurrencyId,CertificationCurrencyId,InspectionCurrencyId,VerificationCurrencyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate FROM INSERTED



End