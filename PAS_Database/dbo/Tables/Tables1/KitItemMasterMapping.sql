﻿CREATE TABLE [dbo].[KitItemMasterMapping] (
    [KitItemMasterMappingId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [KitId]                  BIGINT          NOT NULL,
    [ItemMasterId]           BIGINT          NOT NULL,
    [ManufacturerId]         BIGINT          NOT NULL,
    [ConditionId]            BIGINT          NOT NULL,
    [UOMId]                  BIGINT          NOT NULL,
    [Qty]                    INT             NULL,
    [UnitCost]               DECIMAL (18, 2) NULL,
    [StocklineUnitCost]      DECIMAL (18, 2) NULL,
    [PartNumber]             VARCHAR (250)   NULL,
    [PartDescription]        VARCHAR (MAX)   NULL,
    [Manufacturer]           VARCHAR (256)   NULL,
    [Condition]              VARCHAR (256)   NULL,
    [UOM]                    VARCHAR (256)   NULL,
    [MasterCompanyId]        INT             NULL,
    [CreatedBy]              VARCHAR (256)   NULL,
    [UpdatedBy]              VARCHAR (256)   NULL,
    [CreatedDate]            DATETIME2 (7)   CONSTRAINT [DF_KitItemMasterMapping_CreatedDate] DEFAULT (getdate()) NULL,
    [UpdatedDate]            DATETIME2 (7)   CONSTRAINT [DF_KitItemMasterMapping_UpdatedDate] DEFAULT (getdate()) NULL,
    [IsActive]               BIT             CONSTRAINT [DF_KitItemMasterMapping_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]              BIT             CONSTRAINT [DF_KitItemMasterMapping_isDelete] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_KitItemMasterMapping] PRIMARY KEY CLUSTERED ([KitItemMasterMappingId] ASC),
    CONSTRAINT [FK_KitItemMasterMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

