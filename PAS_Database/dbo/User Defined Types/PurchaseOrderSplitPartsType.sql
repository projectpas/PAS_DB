﻿CREATE TYPE [dbo].[PurchaseOrderSplitPartsType] AS TABLE (
    [PoPartSrNum]               INT            NULL,
    [PoSplitPartSrNum]          INT            NULL,
    [PurchaseOrderPartRecordId] BIGINT         NULL,
    [PurchaseOrderId]           BIGINT         NULL,
    [ItemMasterId]              BIGINT         NULL,
    [PartNumber]                NVARCHAR (MAX) NULL,
    [PartDescription]           NVARCHAR (MAX) NULL,
    [POPartSplitUserTypeId]     INT            NULL,
    [POPartSplitUserType]       NVARCHAR (MAX) NULL,
    [POPartSplitUserId]         BIGINT         NULL,
    [POPartSplitUser]           NVARCHAR (MAX) NULL,
    [POPartSplitSiteId]         BIGINT         NULL,
    [POPartSplitSiteName]       NVARCHAR (MAX) NULL,
    [POPartSplitAddressId]      BIGINT         NULL,
    [POPartSplitAddress1]       NVARCHAR (MAX) NULL,
    [POPartSplitAddress2]       NVARCHAR (MAX) NULL,
    [POPartSplitAddress3]       NVARCHAR (MAX) NULL,
    [POPartSplitCity]           NVARCHAR (MAX) NULL,
    [POPartSplitState]          NVARCHAR (MAX) NULL,
    [POPartSplitPostalCode]     NVARCHAR (MAX) NULL,
    [POPartSplitCountryId]      INT            NULL,
    [POPartSplitCountryName]    NVARCHAR (MAX) NULL,
    [UOMId]                     BIGINT         NULL,
    [UnitOfMeasure]             NVARCHAR (MAX) NULL,
    [PriorityId]                BIGINT         NULL,
    [Priority]                  NVARCHAR (MAX) NULL,
    [QuantityOrdered]           INT            NULL,
    [NeedByDate]                DATETIME       NULL,
    [ManagementStructureId]     BIGINT         NULL,
    [Level1]                    NVARCHAR (MAX) NULL,
    [Level2]                    NVARCHAR (MAX) NULL,
    [Level3]                    NVARCHAR (MAX) NULL,
    [Level4]                    NVARCHAR (MAX) NULL,
    [IsParent]                  BIT            DEFAULT ((0)) NULL,
    [ParentId]                  BIGINT         NULL,
    [IsApproved]                BIT            DEFAULT ((0)) NULL,
    [EstDeliveryDate]           DATETIME       NULL,
    [QuantityBackOrdered]       INT            DEFAULT ((0)) NULL,
    [QuantityRejected]          INT            DEFAULT ((0)) NULL,
    [StockLineCount]            BIGINT         DEFAULT ((0)) NULL,
    [DraftedStockLineCount]     BIGINT         DEFAULT ((0)) NULL,
    [LastMSLevel]               NVARCHAR (MAX) NULL,
    [AllMSLevels]               NVARCHAR (MAX) NULL,
    [IsLotAssigned]             BIT            NULL,
    [LotId]                     BIGINT         NULL,
    [MasterCompanyId]           INT            NULL,
    [CreatedBy]                 NVARCHAR (MAX) NULL,
    [CreatedDate]               DATETIME       DEFAULT (getutcdate()) NULL,
    [UpdatedBy]                 NVARCHAR (MAX) NULL,
    [UpdatedDate]               DATETIME       DEFAULT (getutcdate()) NULL,
    [IsActive]                  BIT            DEFAULT ((1)) NULL,
    [IsDeleted]                 BIT            DEFAULT ((0)) NULL);
