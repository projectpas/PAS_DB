CREATE TABLE [dbo].[VendorRMA] (
    [VendorRMAId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [RMANumber]         VARCHAR (100)  NOT NULL,
    [VendorId]          BIGINT         NOT NULL,
    [OpenDate]          DATETIME2 (7)  NOT NULL,
    [VendorRMAStatusId] INT            NOT NULL,
    [RequestedById]     BIGINT         NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [DF_VendorRMA_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [DF_VendorRMA_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [DF_VendorRMA_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [DF_VendorRMA_IsDeleted] DEFAULT ((0)) NOT NULL,
    [Notes]             NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_VendorRMA] PRIMARY KEY CLUSTERED ([VendorRMAId] ASC),
    CONSTRAINT [FK_VendorRMA_Employee] FOREIGN KEY ([RequestedById]) REFERENCES [dbo].[Employee] ([EmployeeId]),
    CONSTRAINT [FK_VendorRMA_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId])
);

