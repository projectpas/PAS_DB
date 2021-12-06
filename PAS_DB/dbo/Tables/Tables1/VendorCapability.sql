CREATE TABLE [dbo].[VendorCapability] (
    [VendorCapabilityId]        BIGINT          IDENTITY (1, 1) NOT NULL,
    [VendorId]                  BIGINT          NOT NULL,
    [CapabilityTypeId]          INT             NOT NULL,
    [CapabilityTypeName]        VARCHAR (100)   NULL,
    [ItemMasterId]              BIGINT          NOT NULL,
    [CapabilityTypeDescription] VARCHAR (256)   NULL,
    [VendorRanking]             INT             NOT NULL,
    [IsPMA]                     BIT             CONSTRAINT [DF__VendorCap__IsPMA__597119F2] DEFAULT ((0)) NOT NULL,
    [IsDER]                     BIT             CONSTRAINT [DF__VendorCap__IsDER__5A653E2B] DEFAULT ((0)) NOT NULL,
    [Cost]                      DECIMAL (18, 2) NULL,
    [TAT]                       INT             NULL,
    [Memo]                      NVARCHAR (MAX)  NULL,
    [MasterCompanyId]           INT             NOT NULL,
    [CreatedBy]                 VARCHAR (256)   NOT NULL,
    [UpdatedBy]                 VARCHAR (256)   NOT NULL,
    [CreatedDate]               DATETIME2 (7)   CONSTRAINT [VendorCapabiliy_DC_CD] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]               DATETIME2 (7)   CONSTRAINT [VendorCapabiliy_DC_UD] DEFAULT (getdate()) NOT NULL,
    [IsActive]                  BIT             CONSTRAINT [VendorCapabiliy_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                 BIT             CONSTRAINT [VendorCapabiliy_DC_Delete] DEFAULT ((0)) NOT NULL,
    [PartNumber]                VARCHAR (100)   NULL,
    [PartDescription]           VARCHAR (255)   NULL,
    [ManufacturerId]            BIGINT          NULL,
    [ManufacturerName]          VARCHAR (100)   NULL,
    CONSTRAINT [PK_VendorCapabiliy] PRIMARY KEY CLUSTERED ([VendorCapabilityId] ASC),
    CONSTRAINT [FK_VendorCapability_CapabilityTypeId] FOREIGN KEY ([CapabilityTypeId]) REFERENCES [dbo].[CapabilityType] ([CapabilityTypeId]),
    CONSTRAINT [FK_VendorCapability_ItemMasterId] FOREIGN KEY ([ItemMasterId]) REFERENCES [dbo].[ItemMaster] ([ItemMasterId]),
    CONSTRAINT [FK_VendorCapability_ManufactureId] FOREIGN KEY ([ManufacturerId]) REFERENCES [dbo].[Manufacturer] ([ManufacturerId]),
    CONSTRAINT [FK_VendorCapabiliy_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_VendorCapabiliy_Vendor] FOREIGN KEY ([VendorId]) REFERENCES [dbo].[Vendor] ([VendorId]),
    CONSTRAINT [Unique_VendorCapability] UNIQUE NONCLUSTERED ([VendorId] ASC, [CapabilityTypeId] ASC, [ItemMasterId] ASC, [MasterCompanyId] ASC, [IsPMA] ASC, [IsDER] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_VendorCapabilityAudit]

   ON  [dbo].[VendorCapability]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].VendorCapabilityAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END