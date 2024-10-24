﻿CREATE TYPE [dbo].[VendorCreditMemoDetailType] AS TABLE (
    [VendorCreditMemoDetailId] BIGINT          NULL,
    [VendorCreditMemoId]       BIGINT          NULL,
    [VendorRMADetailId]        BIGINT          NULL,
    [VendorRMAId]              BIGINT          NULL,
    [Qty]                      INT             NULL,
    [OriginalAmt]              DECIMAL (18, 2) NULL,
    [ApplierdAmt]              DECIMAL (18, 2) NULL,
    [RefundAmt]                DECIMAL (18, 2) NULL,
    [RefundDate]               DATETIME2 (7)   NULL,
    [Notes]                    VARCHAR (MAX)   NULL,
    [MasterCompanyId]          INT             NULL,
    [CreatedBy]                VARCHAR (256)   NULL,
    [UpdatedBy]                VARCHAR (256)   NULL,
    [CreatedDate]              DATETIME2 (7)   NULL,
    [UpdatedDate]              DATETIME2 (7)   NULL,
    [IsActive]                 BIT             NULL,
    [IsDeleted]                BIT             NULL,
    [UnitCost]                 DECIMAL (18, 2) NULL,
    [StockLineId]              BIGINT          NULL);



