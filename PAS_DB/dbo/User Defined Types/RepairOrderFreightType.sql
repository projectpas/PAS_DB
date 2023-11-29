﻿CREATE TYPE [dbo].[RepairOrderFreightType] AS TABLE (
    [RepairOrderFreightId]     BIGINT          NULL,
    [RepairOrderId]            BIGINT          NULL,
    [RepairOrderPartRecordId]  BIGINT          NULL,
    [ItemMasterId]             BIGINT          NULL,
    [PartNumber]               VARCHAR (150)   NULL,
    [ShipViaId]                BIGINT          NULL,
    [ShipViaName]              VARCHAR (100)   NULL,
    [MarkupPercentageId]       BIGINT          NULL,
    [MarkupFixedPrice]         DECIMAL (20, 2) NULL,
    [HeaderMarkupId]           BIGINT          NULL,
    [BillingMethodId]          INT             NULL,
    [BillingRate]              DECIMAL (20, 2) NULL,
    [BillingAmount]            DECIMAL (20, 2) NULL,
    [HeaderMarkupPercentageId] BIGINT          NULL,
    [Weight]                   VARCHAR (50)    NULL,
    [UOMId]                    BIGINT          NULL,
    [UOMName]                  VARCHAR (100)   NULL,
    [Length]                   DECIMAL (10, 2) NULL,
    [Width]                    DECIMAL (10, 2) NULL,
    [Height]                   DECIMAL (10, 2) NULL,
    [DimensionUOMId]           BIGINT          NULL,
    [DimensionUOMName]         VARCHAR (100)   NULL,
    [CurrencyId]               INT             NULL,
    [CurrencyName]             VARCHAR (100)   NULL,
    [Amount]                   DECIMAL (20, 3) NULL,
    [Memo]                     NVARCHAR (MAX)  NULL,
    [MasterCompanyId]          INT             NULL,
    [CreatedBy]                VARCHAR (256)   NULL,
    [UpdatedBy]                VARCHAR (256)   NULL,
    [CreatedDate]              DATETIME2 (7)   NULL,
    [UpdatedDate]              DATETIME2 (7)   NULL,
    [IsActive]                 BIT             NULL,
    [IsDeleted]                BIT             NULL,
    [LineNum]                  INT             NULL,
    [ManufacturerId]           BIGINT          NULL,
    [Manufacturer]             VARCHAR (100)   NULL);



