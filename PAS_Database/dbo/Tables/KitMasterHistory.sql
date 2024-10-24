﻿CREATE TABLE [dbo].[KitMasterHistory] (
    [KitMasterHistoryId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [KitId]              BIGINT          NOT NULL,
    [KitNumber]          VARCHAR (100)   NULL,
    [ItemMasterId]       BIGINT          NULL,
    [ManufacturerId]     BIGINT          NULL,
    [PartNumber]         VARCHAR (200)   NOT NULL,
    [PartDescription]    VARCHAR (500)   NOT NULL,
    [Manufacturer]       VARCHAR (100)   NOT NULL,
    [MasterCompanyId]    INT             NULL,
    [CreatedBy]          VARCHAR (256)   NULL,
    [UpdatedBy]          VARCHAR (256)   NULL,
    [CreatedDate]        DATETIME2 (7)   CONSTRAINT [DF_KitMasterHistory_CreatedDate] DEFAULT (getutcdate()) NULL,
    [UpdatedDate]        DATETIME2 (7)   CONSTRAINT [DF_KitMasterHistory_UpdatedDate] DEFAULT (getutcdate()) NULL,
    [IsActive]           BIT             CONSTRAINT [DF__KitMasterHistory__IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]          BIT             CONSTRAINT [DF__KitMasterHistory__IsDeleted] DEFAULT ((0)) NULL,
    [CustomerId]         BIGINT          NULL,
    [CustomerName]       VARCHAR (250)   NULL,
    [KitCost]            DECIMAL (18, 2) NOT NULL,
    [KitDescription]     VARCHAR (MAX)   NULL,
    [WorkScopeId]        BIGINT          NULL,
    [WorkScopeName]      VARCHAR (250)   NULL,
    [Memo]               VARCHAR (MAX)   NULL,
    CONSTRAINT [PK_KitMasterHistory] PRIMARY KEY CLUSTERED ([KitMasterHistoryId] ASC)
);



