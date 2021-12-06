CREATE TABLE [dbo].[ShippingReferenceAudit] (
    [ShippingReferenceAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShippingReferenceId]      BIGINT         NOT NULL,
    [Name]                     NVARCHAR (200) NOT NULL,
    [Memo]                     NVARCHAR (MAX) NULL,
    [MasterCompanyId]          INT            NULL,
    [CreatedBy]                VARCHAR (1)    NULL,
    [UpdatedBy]                VARCHAR (1)    NULL,
    [CreatedDate]              DATETIME2 (7)  NULL,
    [UpdatedDate]              DATETIME2 (7)  NULL,
    [IsActive]                 BIT            NULL,
    [IsDeleted]                BIT            NULL,
    PRIMARY KEY CLUSTERED ([ShippingReferenceAuditId] ASC)
);

