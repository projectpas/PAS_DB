CREATE TABLE [dbo].[LeaseStocklineServiceComponentAudit] (
    [LeaseStocklineServiceComponentAuditId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [LeaseStocklineServiceComponentId]      BIGINT          NULL,
    [LeaseStocklineId]                      BIGINT          NULL,
    [ComponentName]                         NVARCHAR (200)  NULL,
    [Amount]                                DECIMAL (18, 6) NULL,
    [Per]                                   NVARCHAR (50)   NULL,
    [MasterCompanyId]                       INT             NULL,
    [CreatedBy]                             VARCHAR (256)   NULL,
    [UpdatedBy]                             VARCHAR (256)   NULL,
    [CreatedDate]                           DATETIME        NULL,
    [UpdatedDate]                           DATETIME        NULL,
    [IsActive]                              BIT             NULL,
    [IsDeleted]                             BIT             NULL,
    CONSTRAINT [PK_LeaseStocklineServiceComponentAudit] PRIMARY KEY CLUSTERED ([LeaseStocklineServiceComponentAuditId] ASC)
);

