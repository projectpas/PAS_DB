﻿CREATE TABLE [dbo].[WorkOrderCustomsInfoAudit] (
    [WorkOrderCustomsInfoAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [WorkOrderCustomsInfoId]      BIGINT          NOT NULL,
    [WorkOrderShippingId]         BIGINT          NOT NULL,
    [EntryType]                   VARCHAR (100)   NULL,
    [EPU]                         VARCHAR (100)   NULL,
    [CustomsValue]                DECIMAL (20, 2) NULL,
    [NetMass]                     DECIMAL (20, 2) NULL,
    [EntryStatus]                 VARCHAR (100)   NULL,
    [EntryNumber]                 VARCHAR (100)   NULL,
    [VATValue]                    DECIMAL (20, 2) NULL,
    [UCR]                         VARCHAR (100)   NULL,
    [MasterUCR]                   VARCHAR (100)   NULL,
    [MovementRefNo]               VARCHAR (100)   NULL,
    [CommodityCode]               VARCHAR (100)   NULL,
    [MasterCompanyId]             INT             NOT NULL,
    [CreatedBy]                   VARCHAR (256)   NOT NULL,
    [UpdatedBy]                   VARCHAR (256)   NOT NULL,
    [CreatedDate]                 DATETIME2 (7)   NOT NULL,
    [UpdatedDate]                 DATETIME2 (7)   NOT NULL,
    [IsActive]                    BIT             NOT NULL,
    [IsDeleted]                   BIT             NOT NULL,
    [CustomCurrencyId]            INT             NULL,
    CONSTRAINT [PK_WorkOrderCustomsInfoAudit] PRIMARY KEY CLUSTERED ([WorkOrderCustomsInfoAuditId] ASC)
);



