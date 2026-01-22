CREATE TABLE [dbo].[ExchCoreMonitoringStatus] (
    [ExchangeCoreMonitoringStatusId] INT          IDENTITY (1, 1) NOT NULL,
    [Name]                           VARCHAR (50) NOT NULL,
    [MasterCompanyId]                INT          NOT NULL,
    [CreatedBy]                      VARCHAR (50) NOT NULL,
    [CreatedOn]                      DATETIME     CONSTRAINT [DF_ExchCoreMonitoringStatus_CreatedOn] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]                      VARCHAR (50) NULL,
    [UpdatedOn]                      DATETIME     CONSTRAINT [DF_ExchCoreMonitoringStatus_UpdatedOn] DEFAULT (getdate()) NULL,
    [IsActive]                       BIT          CONSTRAINT [DF_ExchCoreMonitoringStatus_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                      BIT          CONSTRAINT [DF_ExchCoreMonitoringStatus_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_ExchCoreMonitoringStatus] PRIMARY KEY CLUSTERED ([ExchangeCoreMonitoringStatusId] ASC)
);

