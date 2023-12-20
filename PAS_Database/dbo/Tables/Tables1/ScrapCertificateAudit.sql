CREATE TABLE [dbo].[ScrapCertificateAudit] (
    [ScrapCertificateAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ScrapCertificateId]      BIGINT        NOT NULL,
    [WorkOrderId]             BIGINT        NULL,
    [workOrderPartNoId]       BIGINT        NULL,
    [IsExternal]              BIT           NULL,
    [ScrapedByEmployeeId]     BIGINT        NULL,
    [ScrapedByVendorId]       BIGINT        NULL,
    [CertifiedById]           BIGINT        NULL,
    [ScrapReasonId]           BIGINT        NULL,
    [MasterCompanyId]         INT           NOT NULL,
    [CreatedBy]               VARCHAR (256) NOT NULL,
    [UpdatedBy]               VARCHAR (256) NOT NULL,
    [CreatedDate]             DATETIME2 (7) NOT NULL,
    [UpdatedDate]             DATETIME2 (7) NOT NULL,
    [IsActive]                BIT           NOT NULL,
    [IsDeleted]               BIT           NOT NULL,
    [isSubWorkOrder]          BIT           NULL,
    CONSTRAINT [PK_ScrapCertificateAudit] PRIMARY KEY CLUSTERED ([ScrapCertificateAuditId] ASC)
);

