CREATE TABLE [dbo].[VendorOrderType] (
    [VendorOrderTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [OrderTypeName]     VARCHAR (100) NOT NULL,
    [Description]       VARCHAR (500) NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorOrderType_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorOrderType_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [VendorOrderType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [VendorOrderType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]   INT           NULL,
    CONSTRAINT [PK_VendorOrderType] PRIMARY KEY CLUSTERED ([VendorOrderTypeId] ASC)
);

