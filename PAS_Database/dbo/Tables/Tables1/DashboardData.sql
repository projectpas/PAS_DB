CREATE TABLE [dbo].[DashboardData] (
    [Id]                       BIGINT          IDENTITY (1, 1) NOT NULL,
    [MROInputCount]            INT             NULL,
    [ExecutionDate]            DATETIME        NULL,
    [MasterCompanyId]          BIGINT          NULL,
    [MROBillingAmount]         DECIMAL (20, 2) NULL,
    [PartsSaleBillingAmount]   DECIMAL (20, 2) NULL,
    [MROWorkableBacklog]       INT             NULL,
    [PartsSaleWorkableBacklog] DECIMAL (20, 2) NULL,
    [WOQProcessed]             INT             NULL,
    [SOQProcessed]             DECIMAL (20, 2) NULL,
    [SQProcessed]              INT             NULL,
    CONSTRAINT [PK_tblDashboardData] PRIMARY KEY CLUSTERED ([Id] ASC)
);

