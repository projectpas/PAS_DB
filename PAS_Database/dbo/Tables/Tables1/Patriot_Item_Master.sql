﻿CREATE TABLE [dbo].[Patriot_Item_Master] (
    [ItemTypeId]              INT           NULL,
    [PN]                      NVARCHAR (50) NULL,
    [DESCRIPTION]             NVARCHAR (50) NULL,
    [Classification]          NVARCHAR (50) NULL,
    [ItemClassificationId]    BIGINT        NULL,
    [Group]                   NVARCHAR (50) NULL,
    [ItemGroupId]             BIGINT        NULL,
    [Manuacturer]             NVARCHAR (50) NULL,
    [ManufacturerId]          BIGINT        NULL,
    [Puchase_UOM]             NVARCHAR (50) NULL,
    [PurchaseUnitOfMeasureId] BIGINT        NULL,
    [Puchase_Currency]        NVARCHAR (50) NULL,
    [PurchaseCurrencyId]      BIGINT        NULL,
    [Sales_Currency]          NVARCHAR (50) NULL,
    [SalesCurrencyId]         NCHAR (10)    NULL,
    [GL_Account_Number]       SMALLINT      NULL,
    [GLAccountId]             BIGINT        NULL,
    [Site]                    NVARCHAR (50) NULL,
    [SiteId]                  BIGINT        NULL,
    [Warehouse]               NVARCHAR (50) NULL,
    [WarehouseId]             BIGINT        NULL,
    [Location]                NVARCHAR (50) NULL,
    [LocationId]              BIGINT        NULL
);

