CREATE TABLE [dbo].[VendorContactAudit] (
    [AuditVendorContactId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorContactId]      BIGINT        NOT NULL,
    [VendorId]             BIGINT        NOT NULL,
    [ContactId]            BIGINT        NOT NULL,
    [Tag]                  VARCHAR (255) NOT NULL,
    [IsDefaultContact]     BIT           NOT NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    [ContactTagId]         BIGINT        NULL,
    [Attention]            VARCHAR (250) NULL,
    [IsRestrictedParty]    BIT           NULL,
    CONSTRAINT [PK_VendorContactAudit] PRIMARY KEY CLUSTERED ([AuditVendorContactId] ASC),
    CONSTRAINT [FK_VendorContactAudit_VendorContact] FOREIGN KEY ([VendorContactId]) REFERENCES [dbo].[VendorContact] ([VendorContactId])
);

