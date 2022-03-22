CREATE TABLE [dbo].[VendorRFQStatus] (
    [VendorRFQStatusId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]       VARCHAR (MAX)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [VendorRFQStatus_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [VendorRFQStatus_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [VendorRFQStatus_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [VendorRFQStatus_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Status]            VARCHAR (256)  NOT NULL,
    [SequenceNo]        INT            NULL,
    CONSTRAINT [PK_VendorRFQStatus] PRIMARY KEY CLUSTERED ([VendorRFQStatusId] ASC),
    CONSTRAINT [Unique_VendorRFQStatus] UNIQUE NONCLUSTERED ([Status] ASC, [MasterCompanyId] ASC)
);

