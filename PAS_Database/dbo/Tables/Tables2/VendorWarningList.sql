CREATE TABLE [dbo].[VendorWarningList] (
    [VendorWarningListId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                VARCHAR (100)  NOT NULL,
    [Memo]                NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_VendorWarningList_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_VendorWarningList_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NOT NULL,
    [IsActive]            BIT            CONSTRAINT [VendorWarningList_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [VendorWarningList_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorWarningList] PRIMARY KEY CLUSTERED ([VendorWarningListId] ASC),
    CONSTRAINT [UQ_VendorWarningList_codes] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);

