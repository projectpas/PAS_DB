CREATE TABLE [dbo].[CustomerWarningAudit] (
    [AuditCustomerWarningId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerWarningId]      BIGINT        NOT NULL,
    [CustomerId]             BIGINT        NOT NULL,
    [WarningMessage]         VARCHAR (300) NULL,
    [RestrictMessage]        VARCHAR (300) NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) NOT NULL,
    [IsActive]               BIT           NOT NULL,
    [IsDeleted]              BIT           NOT NULL,
    [Allow]                  BIT           NOT NULL,
    [Warning]                BIT           NOT NULL,
    [Restrict]               BIT           NOT NULL,
    [CustomerWarningListId]  BIGINT        NULL,
    [CustomerWarningsId]     BIGINT        NULL,
    CONSTRAINT [PK_CustomerWarningAudit] PRIMARY KEY CLUSTERED ([AuditCustomerWarningId] ASC)
);

