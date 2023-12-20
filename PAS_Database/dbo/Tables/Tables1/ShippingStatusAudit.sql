CREATE TABLE [dbo].[ShippingStatusAudit] (
    [ShippingStatusAuditId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShippingStatusId]      BIGINT         NOT NULL,
    [Status]                VARCHAR (50)   NOT NULL,
    [Memo]                  NVARCHAR (MAX) NULL,
    [MasterCompanyId]       INT            NOT NULL,
    [CreatedBy]             VARCHAR (256)  NOT NULL,
    [UpdatedBy]             VARCHAR (256)  NOT NULL,
    [CreatedDate]           DATETIME2 (7)  NOT NULL,
    [UpdatedDate]           DATETIME2 (7)  NOT NULL,
    [IsActive]              BIT            NOT NULL,
    [IsDeleted]             BIT            NOT NULL,
    [SequenceNo]            INT            NULL,
    CONSTRAINT [PK_ShippingStatusAudit] PRIMARY KEY CLUSTERED ([ShippingStatusAuditId] ASC)
);

