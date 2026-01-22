CREATE TABLE [dbo].[ShippingTermsAudit] (
    [AuditShippingTermsId] INT            IDENTITY (1, 1) NOT NULL,
    [ShippingTermsId]      INT            NOT NULL,
    [Description]          NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedDate]          DATETIME2 (7)  NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [IsActive]             BIT            NOT NULL,
    [IsDeleted]            BIT            NOT NULL,
    [Name]                 VARCHAR (256)  NOT NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [SequenceNo]           INT            NULL,
    CONSTRAINT [PK_ShippingTermsAudit] PRIMARY KEY CLUSTERED ([AuditShippingTermsId] ASC)
);

