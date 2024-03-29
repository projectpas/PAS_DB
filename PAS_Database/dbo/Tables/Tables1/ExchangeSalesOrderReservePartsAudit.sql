﻿CREATE TABLE [dbo].[ExchangeSalesOrderReservePartsAudit] (
    [AuditExchangeSalesOrderReservePartId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ExchangeSalesOrderReservePartId]      BIGINT        NOT NULL,
    [ExchangeSalesOrderId]                 BIGINT        NULL,
    [StockLineId]                          BIGINT        NOT NULL,
    [ItemMasterId]                         BIGINT        NOT NULL,
    [PartStatusId]                         INT           NOT NULL,
    [IsEquPart]                            BIT           NOT NULL,
    [EquPartMasterPartId]                  BIGINT        NULL,
    [IsAltPart]                            BIT           NOT NULL,
    [AltPartMasterPartId]                  BIGINT        NULL,
    [QtyToReserve]                         INT           NULL,
    [QtyToIssued]                          INT           NULL,
    [ReservedById]                         BIGINT        NULL,
    [ReservedDate]                         DATETIME2 (7) NULL,
    [IssuedById]                           BIGINT        NULL,
    [IssuedDate]                           DATETIME2 (7) NULL,
    [CreatedBy]                            VARCHAR (256) NOT NULL,
    [CreatedDate]                          DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderReservePartsAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                            VARCHAR (256) NOT NULL,
    [UpdatedDate]                          DATETIME2 (7) CONSTRAINT [DF_ExchangeSalesOrderReservePartsAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                             BIT           CONSTRAINT [DF_ExchangeSalesOrderReservePartsAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                            BIT           CONSTRAINT [DF_ExchangeSalesOrderReservePartsAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ExchangeSalesOrderPartId]             BIGINT        NOT NULL,
    [TotalReserved]                        INT           NULL,
    [TotalIssued]                          INT           NULL,
    [MasterCompanyId]                      INT           NOT NULL,
    CONSTRAINT [PK_ExchangeSalesOrderReservePartsAudit] PRIMARY KEY CLUSTERED ([AuditExchangeSalesOrderReservePartId] ASC)
);

