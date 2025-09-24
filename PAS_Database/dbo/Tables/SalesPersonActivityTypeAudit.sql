CREATE TABLE [dbo].[SalesPersonActivityTypeAudit] (
    [AuditSalesPersonActivityTypeId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SalesPersonActivityTypeId]      BIGINT        NULL,
    [CustomerId]                     BIGINT        NULL,
    [DropdownTypeId]                 BIGINT        NULL,
    [ActivityTypeId]                 BIGINT        NULL,
    [RevenuePercentageId]            BIGINT        NULL,
    [MarginPercentageId]             BIGINT        NULL,
    [EffectiveDate]                  DATETIME2 (7) NULL,
    [EntityStructureId]              BIGINT        NULL,
    [Level1]                         VARCHAR (256) NULL,
    [Level2]                         VARCHAR (256) NULL,
    [Level3]                         VARCHAR (256) NULL,
    [Level4]                         VARCHAR (256) NULL,
    [MasterCompanyId]                INT           NOT NULL,
    [CreatedBy]                      VARCHAR (256) NOT NULL,
    [UpdatedBy]                      VARCHAR (256) NOT NULL,
    [CreatedDate]                    DATETIME2 (7) NOT NULL,
    [UpdatedDate]                    DATETIME2 (7) NOT NULL,
    [IsActive]                       BIT           NOT NULL,
    [IsDeleted]                      BIT           NOT NULL,
    CONSTRAINT [PK_SalesPersonActivityTypeAudit] PRIMARY KEY CLUSTERED ([AuditSalesPersonActivityTypeId] ASC)
);

