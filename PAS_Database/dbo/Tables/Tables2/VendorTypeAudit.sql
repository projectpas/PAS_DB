CREATE TABLE [dbo].[VendorTypeAudit] (
    [AuditVendorTypeId] INT            IDENTITY (1, 1) NOT NULL,
    [VendorTypeId]      INT            NOT NULL,
    [Description]       NVARCHAR (256) NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [VendorTypeName]    VARCHAR (256)  NOT NULL,
    CONSTRAINT [PK_VendorTypeAudit] PRIMARY KEY CLUSTERED ([AuditVendorTypeId] ASC),
    CONSTRAINT [FK_VendorTypeAudit_VendorType] FOREIGN KEY ([VendorTypeId]) REFERENCES [dbo].[VendorType] ([VendorTypeId])
);

