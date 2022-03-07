﻿CREATE TABLE [dbo].[CalibrationManagmentAudit] (
    [CalibrationAuditId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [CalibrationId]       BIGINT          NOT NULL,
    [AssetRecordId]       BIGINT          NOT NULL,
    [LastCalibrationDate] DATETIME        NULL,
    [NextCalibrationDate] DATETIME        NULL,
    [LastCalibrationBy]   VARCHAR (50)    NULL,
    [VendorId]            BIGINT          NULL,
    [VendorName]          VARCHAR (100)   NULL,
    [EmployeeId]          BIGINT          NULL,
    [EmployeeName]        VARCHAR (100)   NULL,
    [CalibrationDate]     DATETIME        NULL,
    [CurrencyId]          INT             NULL,
    [CurrencyName]        VARCHAR (50)    NULL,
    [UnitCost]            DECIMAL (18, 2) NULL,
    [CertifyType]         VARCHAR (200)   NULL,
    [CertifyId]           BIGINT          NULL,
    [Memo]                NVARCHAR (MAX)  NULL,
    [MasterCompanyId]     INT             NOT NULL,
    [IsDeleted]           BIT             NOT NULL,
    [IsActive]            BIT             NOT NULL,
    [CreatedBy]           VARCHAR (256)   NOT NULL,
    [UpdatedBy]           VARCHAR (256)   NOT NULL,
    [CreatedDate]         DATETIME2 (7)   NOT NULL,
    [UpdatedDate]         DATETIME2 (7)   NOT NULL,
    [IsVendororEmployee]  VARCHAR (20)    NULL,
    [AssetInventoryId]    BIGINT          NULL,
    [CalibrationTypeId]   BIGINT          NULL,
    CONSTRAINT [PK_CalibrationManagmentAudit] PRIMARY KEY CLUSTERED ([CalibrationAuditId] ASC)
);



