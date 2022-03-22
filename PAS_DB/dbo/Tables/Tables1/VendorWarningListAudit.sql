CREATE TABLE [dbo].[VendorWarningListAudit] (
    [VendorWarningListAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [VendorWarningListId]      BIGINT         NOT NULL,
    [Name]                     VARCHAR (100)  NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]          INT            NOT NULL,
    [CreatedDate]              DATETIME2 (7)  NOT NULL,
    [UpdatedDate]              DATETIME2 (7)  NOT NULL,
    [CreatedBy]                VARCHAR (256)  NOT NULL,
    [UpdatedBy]                VARCHAR (256)  NOT NULL,
    [IsActive]                 BIT            NOT NULL,
    [IsDeleted]                BIT            NOT NULL,
    CONSTRAINT [PK_VendorWarningListAudit] PRIMARY KEY CLUSTERED ([VendorWarningListAuditId] ASC)
);

