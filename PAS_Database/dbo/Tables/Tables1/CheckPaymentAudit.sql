CREATE TABLE [dbo].[CheckPaymentAudit] (
    [AuditCheckPaymentId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CheckPaymentId]      BIGINT        NOT NULL,
    [RoutingNumber]       VARCHAR (30)  NULL,
    [AccountNumber]       VARCHAR (30)  NULL,
    [SiteName]            VARCHAR (100) NULL,
    [IsPrimayPayment]     BIT           NOT NULL,
    [AddressId]           BIGINT        NOT NULL,
    [MasterCompanyId]     INT           NOT NULL,
    [CreatedBy]           VARCHAR (256) NULL,
    [UpdatedBy]           VARCHAR (256) NULL,
    [CreatedDate]         DATETIME2 (7) NOT NULL,
    [UpdatedDate]         DATETIME2 (7) NOT NULL,
    [IsActive]            BIT           NULL,
    [IsDeleted]           BIT           NULL,
    [ContactTagId]        BIGINT        NULL,
    [Attention]           VARCHAR (250) NULL,
    CONSTRAINT [PK_CheckPaymentAudit] PRIMARY KEY CLUSTERED ([AuditCheckPaymentId] ASC)
);

