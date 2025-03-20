CREATE TABLE [dbo].[VendorAuditInfoAudit] (
    [VendorAuditInfoAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorAuditInfoId]      BIGINT        NOT NULL,
    [VendorId]               BIGINT        NOT NULL,
    [VendorOrderTypeId]      BIGINT        NOT NULL,
    [VendorAuditTypeId]      BIGINT        NOT NULL,
    [FrequencyDays]          INT           NULL,
    [LastAuditDate]          DATETIME2 (7) NULL,
    [NextAuditDate]          DATETIME2 (7) NULL,
    [Expired]                VARCHAR (50)  NULL,
    [AuditFindings]          VARCHAR (MAX) NULL,
    [ActionsTaken]           VARCHAR (MAX) NULL,
    [CreatedBy]              VARCHAR (256) NOT NULL,
    [UpdatedBy]              VARCHAR (256) NOT NULL,
    [CreatedDate]            DATETIME2 (7) NOT NULL,
    [UpdatedDate]            DATETIME2 (7) NOT NULL,
    [IsActive]               BIT           NOT NULL,
    [IsDeleted]              BIT           NOT NULL,
    [MasterCompanyId]        INT           NULL,
    CONSTRAINT [PK_VendorAuditInfoAudit] PRIMARY KEY CLUSTERED ([VendorAuditInfoAuditId] ASC)
);

