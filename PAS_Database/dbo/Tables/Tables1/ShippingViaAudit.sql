CREATE TABLE [dbo].[ShippingViaAudit] (
    [AuditShippingViaId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ShippingViaId]      BIGINT         NOT NULL,
    [Name]               NVARCHAR (200) NOT NULL,
    [Memo]               NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  NOT NULL,
    [IsActive]           BIT            NOT NULL,
    [IsDeleted]          BIT            NOT NULL,
    [Description]        VARCHAR (500)  NULL,
    [CarrierId]          BIGINT         NULL,
    PRIMARY KEY CLUSTERED ([AuditShippingViaId] ASC)
);

