CREATE TABLE [dbo].[ShippingConfigureAudit] (
    [ShippingConfigureAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ShippingConfigureId]      BIGINT        NULL,
    [ShippingViaId]            BIGINT        NULL,
    [ApiURL]                   VARCHAR (MAX) NULL,
    [ApiKey]                   VARCHAR (MAX) NULL,
    [SecretKey]                VARCHAR (MAX) NULL,
    [ShippingAccountNumber]    VARCHAR (100) NULL,
    [IsAuthReq]                BIT           NULL,
    [MasterCompanyId]          INT           NULL,
    [CreatedBy]                VARCHAR (100) NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [[ShippingConfigureAudit_DC_CDate] DEFAULT (getdate()) NULL,
    [UpdatedBy]                VARCHAR (100) NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [ShippingConfigureAudit_DC_UDate] DEFAULT (getdate()) NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_ShippingConfigureAudit_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]                BIT           CONSTRAINT [DF_ShippingConfigureAudit_IsDeleted] DEFAULT ((0)) NULL,
    [CarrierId]                BIGINT        NULL,
    CONSTRAINT [PK_ShippingConfigureAudit] PRIMARY KEY CLUSTERED ([ShippingConfigureAuditId] ASC)
);

