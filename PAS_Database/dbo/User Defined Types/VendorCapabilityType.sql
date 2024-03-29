﻿CREATE TYPE [dbo].[VendorCapabilityType] AS TABLE (
    [VendorCapabilityId]        BIGINT          NULL,
    [VendorId]                  BIGINT          NULL,
    [CapabilityTypeId]          INT             NULL,
    [CapabilityTypeName]        VARCHAR (100)   NULL,
    [ItemMasterId]              BIGINT          NULL,
    [CapabilityTypeDescription] VARCHAR (256)   NULL,
    [VendorRanking]             INT             NULL,
    [IsPMA]                     BIT             NULL,
    [IsDER]                     BIT             NULL,
    [Cost]                      DECIMAL (18, 2) NULL,
    [TAT]                       INT             NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [MasterCompanyId]           INT             NULL,
    [CreatedBy]                 VARCHAR (256)   NULL,
    [UpdatedBy]                 VARCHAR (256)   NULL,
    [CreatedDate]               DATETIME2 (7)   NULL,
    [UpdatedDate]               DATETIME2 (7)   NULL,
    [IsActive]                  BIT             NULL,
    [IsDeleted]                 BIT             NULL,
    [PartNumber]                VARCHAR (100)   NULL,
    [PartDescription]           VARCHAR (255)   NULL,
    [ManufacturerId]            BIGINT          NULL,
    [ManufacturerName]          VARCHAR (100)   NULL,
    [CostDate]                  DATETIME        NULL,
    [CurrencyId]                INT             NULL,
    [Currency]                  VARCHAR (50)    NULL,
    [EmployeeId]                INT             NULL);

