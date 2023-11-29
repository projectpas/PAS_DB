CREATE TABLE [dbo].[VendorRMAPackaginSlipHeader] (
    [PackagingSlipId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [PackagingSlipNo] VARCHAR (50)  NOT NULL,
    [VendorRMAId]     BIGINT        NOT NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL,
    [IsActive]        BIT           NOT NULL,
    [IsDeleted]       BIT           NOT NULL,
    [RMAShippingId]   BIGINT        NULL,
    CONSTRAINT [PK_VendorRMAPackaginSlipHeader] PRIMARY KEY CLUSTERED ([PackagingSlipId] ASC)
);

