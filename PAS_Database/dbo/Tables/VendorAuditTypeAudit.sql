CREATE TABLE [dbo].[VendorAuditTypeAudit] (
    [VendorAuditTypeAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorAuditTypeId]      BIGINT         NOT NULL,
    [VendorAuditType]        NVARCHAR (200) NOT NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NOT NULL,
    [CreatedBy]              VARCHAR (256)  NOT NULL,
    [UpdatedBy]              VARCHAR (256)  NOT NULL,
    [CreatedDate]            DATETIME2 (7)  CONSTRAINT [DF_VendorAuditTypeAudit_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7)  CONSTRAINT [DF_VendorAuditTypeAudit_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT            CONSTRAINT [DF_VendorAuditTypeAudit_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT            CONSTRAINT [DF_VendorAuditTypeAudit_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_VendorAuditTypeAudit] PRIMARY KEY CLUSTERED ([VendorAuditTypeAuditId] ASC)
);

