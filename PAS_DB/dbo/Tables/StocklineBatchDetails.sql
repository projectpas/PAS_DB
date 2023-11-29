﻿CREATE TABLE [dbo].[StocklineBatchDetails] (
    [StocklineBatchDetailId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [JournalBatchDetailId]       BIGINT         NULL,
    [JournalBatchHeaderId]       BIGINT         NULL,
    [VendorId]                   BIGINT         NULL,
    [VendorName]                 VARCHAR (100)  NULL,
    [ItemMasterId]               BIGINT         NULL,
    [PartId]                     BIGINT         NULL,
    [PartNumber]                 NVARCHAR (100) NULL,
    [PoId]                       BIGINT         NULL,
    [PONum]                      VARCHAR (50)   NULL,
    [RoId]                       BIGINT         NULL,
    [RONum]                      VARCHAR (50)   NULL,
    [StocklineId]                BIGINT         NULL,
    [StocklineNumber]            VARCHAR (50)   NULL,
    [Consignment]                VARCHAR (50)   NULL,
    [Description]                VARCHAR (MAX)  NULL,
    [SiteId]                     BIGINT         NULL,
    [Site]                       VARCHAR (100)  NULL,
    [WarehouseId]                BIGINT         NULL,
    [Warehouse]                  VARCHAR (100)  NULL,
    [LocationId]                 BIGINT         NULL,
    [Location]                   VARCHAR (100)  NULL,
    [BinId]                      BIGINT         NULL,
    [Bin]                        VARCHAR (100)  NULL,
    [ShelfId]                    BIGINT         NULL,
    [Shelf]                      VARCHAR (100)  NULL,
    [StockType]                  VARCHAR (50)   NULL,
    [CommonJournalBatchDetailId] BIGINT         NULL,
    CONSTRAINT [PK_StocklineBatchDetails] PRIMARY KEY CLUSTERED ([StocklineBatchDetailId] ASC)
);





