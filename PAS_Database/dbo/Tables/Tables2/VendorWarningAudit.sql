CREATE TABLE [dbo].[VendorWarningAudit] (
    [AuditVendorWarningId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorWarningId]      BIGINT        NOT NULL,
    [VendorId]             BIGINT        NOT NULL,
    [Allow]                BIT           NOT NULL,
    [Warning]              BIT           NOT NULL,
    [Restrict]             BIT           NOT NULL,
    [WarningMessage]       VARCHAR (300) NULL,
    [RestrictMessage]      VARCHAR (300) NULL,
    [MasterCompanyId]      INT           NOT NULL,
    [CreatedBy]            VARCHAR (256) NOT NULL,
    [UpdatedBy]            VARCHAR (256) NOT NULL,
    [CreatedDate]          DATETIME2 (7) NOT NULL,
    [UpdatedDate]          DATETIME2 (7) NOT NULL,
    [IsActive]             BIT           NOT NULL,
    [IsDeleted]            BIT           NOT NULL,
    [VendorWarningListId]  BIGINT        NULL,
    CONSTRAINT [PK_VendorWarningAudit] PRIMARY KEY CLUSTERED ([AuditVendorWarningId] ASC),
    CONSTRAINT [FK_VendorWarningAudit_VendorWarning] FOREIGN KEY ([VendorWarningId]) REFERENCES [dbo].[VendorWarning] ([VendorWarningId])
);

