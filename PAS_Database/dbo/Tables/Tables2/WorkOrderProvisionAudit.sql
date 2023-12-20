CREATE TABLE [dbo].[WorkOrderProvisionAudit] (
    [WorkOrderProvisionAuditId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [WorkOrderProvisionId]      TINYINT       NOT NULL,
    [ProvisionDescription]      VARCHAR (30)  NOT NULL,
    [MasterCompanyId]           INT           NOT NULL,
    [CreatedBy]                 VARCHAR (256) NOT NULL,
    [CreatedDate]               DATETIME2 (7) NOT NULL,
    [UpdatedBy]                 VARCHAR (256) NOT NULL,
    [UpdatedDate]               DATETIME2 (7) NOT NULL,
    [IsActive]                  BIT           NOT NULL,
    [IsDeleted]                 BIT           NOT NULL,
    CONSTRAINT [PK_WorkOrderProvisionAudit] PRIMARY KEY CLUSTERED ([WorkOrderProvisionAuditId] ASC)
);

