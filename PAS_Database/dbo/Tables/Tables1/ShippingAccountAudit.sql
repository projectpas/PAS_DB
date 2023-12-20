CREATE TABLE [dbo].[ShippingAccountAudit] (
    [ShippingAccountAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShippingAccountId]      BIGINT         NOT NULL,
    [AccountNumber]          VARCHAR (200)  NULL,
    [Memo]                   NVARCHAR (MAX) NULL,
    [MasterCompanyId]        INT            NULL,
    [CreatedBy]              VARCHAR (1)    NULL,
    [UpdatedBy]              VARCHAR (1)    NULL,
    [CreatedDate]            DATETIME2 (7)  NULL,
    [UpdatedDate]            DATETIME2 (7)  NULL,
    [IsActive]               BIT            NULL,
    [IsDeleted]              BIT            NULL,
    PRIMARY KEY CLUSTERED ([ShippingAccountAuditId] ASC)
);

