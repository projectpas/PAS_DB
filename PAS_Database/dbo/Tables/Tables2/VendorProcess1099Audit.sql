CREATE TABLE [dbo].[VendorProcess1099Audit] (
    [AuditVendorProcess1099Id] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorProcess1099Id]      BIGINT        NOT NULL,
    [VendorId]                 BIGINT        NOT NULL,
    [Master1099Id]             BIGINT        NOT NULL,
    [IsDefaultCheck]           BIT           NOT NULL,
    [IsDefaultRadio]           BIT           NOT NULL,
    [MasterCompanyId]          INT           NOT NULL,
    [CreatedBy]                VARCHAR (256) NOT NULL,
    [UpdatedBy]                VARCHAR (256) NOT NULL,
    [CreatedDate]              DATETIME2 (7) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) NOT NULL,
    [IsActive]                 BIT           NOT NULL,
    [IsDeleted]                BIT           NOT NULL,
    CONSTRAINT [PK_VendorProcess1099Audit] PRIMARY KEY CLUSTERED ([AuditVendorProcess1099Id] ASC),
    CONSTRAINT [FK_VendorProcess1099Audit_VendorProcess1099] FOREIGN KEY ([VendorProcess1099Id]) REFERENCES [dbo].[VendorProcess1099] ([VendorProcess1099Id])
);

