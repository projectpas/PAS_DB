CREATE TABLE [dbo].[ManagementWarehouseAudit] (
    [ManagementWarehouseAuditId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ManagementWarehouseId]      BIGINT        NOT NULL,
    [ManagementStructureId]      BIGINT        NOT NULL,
    [WarehouseId]                BIGINT        NOT NULL,
    [MasterCompanyId]            INT           NOT NULL,
    [CreatedBy]                  VARCHAR (256) NOT NULL,
    [UpdatedBy]                  VARCHAR (256) NOT NULL,
    [CreatedDate]                DATETIME2 (7) NOT NULL,
    [UpdatedDate]                DATETIME2 (7) NOT NULL,
    [IsActive]                   BIT           NOT NULL,
    [IsDeleted]                  BIT           NOT NULL,
    CONSTRAINT [PK_ManagementWarehouseAudit] PRIMARY KEY CLUSTERED ([ManagementWarehouseAuditId] ASC)
);

