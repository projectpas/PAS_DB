CREATE TABLE [dbo].[VendorStatusAudit] (
    [VendorStatusAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorStatusId]      BIGINT        NOT NULL,
    [Description]         VARCHAR (100) NOT NULL,
    [Memo]                VARCHAR (MAX) NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NOT NULL,
    [UpdatedBy]           VARCHAR (256) NOT NULL,
    [CreatedDate]         DATETIME2 (7) CONSTRAINT [DF_VendorStatusAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) CONSTRAINT [DF_VendorStatusAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]            BIT           CONSTRAINT [DF_VendorStatusAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]           BIT           CONSTRAINT [DF_VendorStatusAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorStatusAudit] PRIMARY KEY CLUSTERED ([VendorStatusAuditId] ASC)
);

