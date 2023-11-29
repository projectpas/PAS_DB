CREATE TABLE [dbo].[VendorRMAHeaderStatus] (
    [VendorRMAStatusId] INT           IDENTITY (1, 1) NOT NULL,
    [StatusName]        VARCHAR (50)  NOT NULL,
    [MasterCompanyId]   INT           NOT NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorRMAHeaderStatus_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorRMAHeaderStatus_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [DF_VendorRMAHeaderStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF_VendorRMAHeaderStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Code]              VARCHAR (20)  NOT NULL,
    [SequenceNo]        INT           NULL,
    CONSTRAINT [PK_VendorRMAHeaderStatus] PRIMARY KEY CLUSTERED ([VendorRMAStatusId] ASC)
);

