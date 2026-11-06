CREATE TYPE [dbo].[CustomerRMAReceivePartsType] AS TABLE (
    -- [PN-18254] Receiving Customer RMA: one row = one stockline to create
    [RMADeatilsId]             BIGINT          NOT NULL,
    [QtyToReceive]             DECIMAL (18, 6) NOT NULL,
    [ConditionId]              BIGINT          NULL,
    [SiteId]                   BIGINT          NULL,
    [WarehouseId]              BIGINT          NULL,
    [LocationId]               BIGINT          NULL,
    [ShelfId]                  BIGINT          NULL,
    [BinId]                    BIGINT          NULL,
    [GLAccountId]              BIGINT          NULL,
    [SerialNumber]             VARCHAR (30)    NULL,
    [UnitCost]                 DECIMAL (18, 6) NULL,
    [ManufacturerLotNumber]    VARCHAR (50)    NULL,
    [ManufacturingBatchNumber] VARCHAR (50)    NULL,
    [ManufacturingDate]        DATETIME2 (7)   NULL,
    [ExpirationDate]           DATETIME2 (7)   NULL,
    [PartCertificationNumber]  VARCHAR (50)    NULL,
    [CertifiedDate]            DATETIME2 (7)   NULL,
    [CertTypeId]               VARCHAR (100)   NULL,
    [TagDate]                  DATETIME2 (7)   NULL,
    [TagTypeId]                BIGINT          NULL,
    [Memo]                     NVARCHAR (MAX)  NULL
);
