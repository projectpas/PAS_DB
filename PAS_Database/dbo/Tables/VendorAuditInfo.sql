CREATE TABLE [dbo].[VendorAuditInfo] (
    [VendorAuditInfoId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [VendorId]          BIGINT        NOT NULL,
    [VendorOrderTypeId] BIGINT        NOT NULL,
    [VendorAuditTypeId] BIGINT        NOT NULL,
    [FrequencyDays]     INT           NULL,
    [LastAuditDate]     DATETIME2 (7) NULL,
    [NextAuditDate]     DATETIME2 (7) NULL,
    [Expired]           VARCHAR (50)  NULL,
    [AuditFindings]     VARCHAR (MAX) NULL,
    [ActionsTaken]      VARCHAR (MAX) NULL,
    [CreatedBy]         VARCHAR (256) NOT NULL,
    [UpdatedBy]         VARCHAR (256) NOT NULL,
    [CreatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorAuditInfo_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7) CONSTRAINT [DF_VendorAuditInfo_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT           CONSTRAINT [VendorAuditInfo_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT           CONSTRAINT [VendorAuditInfo_IsDeleted] DEFAULT ((0)) NOT NULL,
    [MasterCompanyId]   INT           NULL,
    CONSTRAINT [PK_VendorAuditInfo] PRIMARY KEY CLUSTERED ([VendorAuditInfoId] ASC),
    CONSTRAINT [FK_VendorAuditInfo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

