﻿CREATE TABLE [dbo].[VendorRMADetail] (
    [VendorRMADetailId]       BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorRMAId]             BIGINT          NULL,
    [RMANum]                  VARCHAR (100)   NULL,
    [StockLineId]             BIGINT          NOT NULL,
    [ReferenceId]             BIGINT          NOT NULL,
    [ItemMasterId]            BIGINT          NOT NULL,
    [SerialNumber]            VARCHAR (50)    NULL,
    [Qty]                     INT             NULL,
    [UnitCost]                DECIMAL (18, 2) NULL,
    [ExtendedCost]            DECIMAL (18, 2) NULL,
    [VendorRMAReturnReasonId] BIGINT          NOT NULL,
    [VendorRMAStatusId]       INT             NOT NULL,
    [VendorShippingAddressId] BIGINT          NULL,
    [Notes]                   NVARCHAR (MAX)  NULL,
    [MasterCompanyId]         INT             NOT NULL,
    [CreatedBy]               VARCHAR (256)   NOT NULL,
    [CreatedDate]             DATETIME2 (7)   CONSTRAINT [DF_VendorRMADetail_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]               VARCHAR (256)   NOT NULL,
    [UpdatedDate]             DATETIME2 (7)   CONSTRAINT [DF_VendorRMADetail_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                BIT             CONSTRAINT [DF_VendorRMADetail_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]               BIT             CONSTRAINT [DF_VendorRMADetail_IsDeleted] DEFAULT ((0)) NOT NULL,
    [QuantityBackOrdered]     INT             NULL,
    [QuantityRejected]        INT             NULL,
    [ModuleId]                INT             NULL,
    [QtyShipped]              INT             NULL,
    CONSTRAINT [PK_VendorRMADetail] PRIMARY KEY CLUSTERED ([VendorRMADetailId] ASC),
    CONSTRAINT [FK_VendorRMADetail_ItemMaster] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_VendorRMADetail_Stockline] FOREIGN KEY ([StockLineId]) REFERENCES [dbo].[Stockline] ([StockLineId]),
    CONSTRAINT [FK_VendorRMADetail_VendorRMA] FOREIGN KEY ([VendorRMAId]) REFERENCES [dbo].[VendorRMA] ([VendorRMAId]),
    CONSTRAINT [FK_VendorRMADetail_VendorRMAReturnReason] FOREIGN KEY ([VendorRMAReturnReasonId]) REFERENCES [dbo].[VendorRMAReturnReason] ([VendorRMAReturnReasonId]),
    CONSTRAINT [FK_VendorRMADetail_VendorRMAStatus] FOREIGN KEY ([VendorRMAStatusId]) REFERENCES [dbo].[VendorRMAStatus] ([VendorRMAStatusId])
);

