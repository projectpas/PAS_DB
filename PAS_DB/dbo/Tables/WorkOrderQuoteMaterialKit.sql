﻿CREATE TABLE [dbo].[WorkOrderQuoteMaterialKit] (
    [KitItemMasterMappingId]  BIGINT          IDENTITY (1, 1) NOT NULL,
    [WOQMaterialKitMappingId] BIGINT          NOT NULL,
    [KitId]                   BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [ManufacturerId]          BIGINT          NOT NULL,
    [ConditionId]             BIGINT          NOT NULL,
    [UOMId]                   BIGINT          NOT NULL,
    [Qty]                     INT             NULL,
    [UnitCost]                DECIMAL (18, 2) NULL,
    [PartNumber]              VARCHAR (100)   NULL,
    [PartDescription]         VARCHAR (MAX)   NULL,
    [Manufacturer]            VARCHAR (256)   NULL,
    [Condition]               VARCHAR (256)   NULL,
    [UOM]                     VARCHAR (256)   NULL,
    [MasterCompanyId]         INT             NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteMaterialKit_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_WorkOrderQuoteMaterialKit_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]                BIT             CONSTRAINT [DF_WorkOrderQuoteMaterialKit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_WorkOrderQuoteMaterialKit_isDelete] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_WorkOrderQuoteMaterialKit] PRIMARY KEY CLUSTERED ([KitItemMasterMappingId] ASC),
    CONSTRAINT [FK_WorkOrderQuoteMaterialKit_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);



