CREATE TABLE [dbo].[RepairOrderSettingMasterAudit] (
    [RepairOrderSettingAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [RepairOrderSettingId]      BIGINT        NOT NULL,
    [IsResale]                  BIT           NOT NULL,
    [IsDeferredReceiver]        BIT           NOT NULL,
    [IsEnforceApproval]         BIT           NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    [Effectivedate]             DATETIME2 (7) NULL,
    [PriorityId]                BIGINT        NULL,
    [Priority]                  VARCHAR (100) NULL,
    [IsRequestor]               BIT           NULL,
    [FreightCOGSRefrenceId]     INT           NULL,
    [TaxCOGSRefrenceId]         INT           NULL,
    CONSTRAINT [PK_RepairOrderSettingMasterAudit] PRIMARY KEY CLUSTERED ([RepairOrderSettingAuditId] ASC)
);



