CREATE TABLE [dbo].[AuditCustomerContact] (
    [AuditCustomerContactId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [CustomerContactId]      BIGINT        NOT NULL,
    [CustomerId]             BIGINT        NOT NULL,
    [ContactId]              BIGINT        NULL,
    [IsDefaultContact]       BIT           NULL,
    [MasterCompanyId]        INT           NOT NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) CONSTRAINT [DF_AuditCustomerContact_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) CONSTRAINT [DF_AuditCustomerContact_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]               BIT           CONSTRAINT [DF_AuditCustomerContact_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]              BIT           CONSTRAINT [DF_AuditCustomerContact_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AuditCustomerContact] PRIMARY KEY CLUSTERED ([AuditCustomerContactId] ASC)
);

