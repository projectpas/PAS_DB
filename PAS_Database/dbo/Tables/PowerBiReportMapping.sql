CREATE TABLE [dbo].[PowerBiReportMapping] (
    [PowerBiReportMappingId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReportKey]       NVARCHAR (100) NOT NULL,
    [ReportName]      NVARCHAR (250) NOT NULL,
    [WorkspaceId]     NVARCHAR (100) NOT NULL,
    [ReportId]        NVARCHAR (100) NOT NULL,
    [DatasetId]       NVARCHAR (100) NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_PowerBiReportMapping_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_PowerBiReportMapping_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_PowerBiReportMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_PowerBiReportMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    [IsMaster]        BIT            CONSTRAINT [DF_PowerBiReportMapping_IsMaster] DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([PowerBiReportMappingId] ASC)
);
GO

CREATE NONCLUSTERED INDEX [IX_PowerBiReportMapping_TenantReport]
    ON [dbo].[PowerBiReportMapping]([MasterCompanyId] ASC, [ReportKey] ASC);
