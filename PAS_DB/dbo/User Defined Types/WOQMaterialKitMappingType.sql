﻿CREATE TYPE [dbo].[WOQMaterialKitMappingType] AS TABLE (
    [WOQMaterialKitMappingId] BIGINT          NULL,
    [WorkOrderQuoteId]        BIGINT          NULL,
    [WorkflowWorkOrderId]     BIGINT          NULL,
    [KitId]                   BIGINT          NULL,
    [KitNumber]               VARCHAR (100)   NULL,
    [ItemMasterId]            BIGINT          NULL,
    [Quantity]                INT             NULL,
    [UnitCost]                DECIMAL (18, 2) NULL,
    [ExtendedCost]            DECIMAL (18, 2) NULL,
    [MasterCompanyId]         INT             NULL,
    [CreatedBy]               VARCHAR (256)   NULL,
    [UpdatedBy]               VARCHAR (256)   NULL,
    [CreatedDate]             DATETIME2 (7)   NULL,
    [UpdatedDate]             DATETIME2 (7)   NULL,
    [IsActive]                BIT             NULL,
    [IsDeleted]               BIT             NULL,
    [Memo]                    VARCHAR (256)   NULL,
    [MarkupPercentageId]      BIGINT          NULL,
    [MarkupFixedPrice]        VARCHAR (256)   NULL,
    [BillingAmount]           DECIMAL (18, 2) NULL,
    [BillingRate]             DECIMAL (18, 2) NULL,
    [HeaderMarkupId]          BIGINT          NULL,
    [BillingMethodId]         INT             NULL);

