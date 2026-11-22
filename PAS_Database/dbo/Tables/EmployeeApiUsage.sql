CREATE TABLE [dbo].[EmployeeApiUsage] (
    [EmployeeApiUsageId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]         BIGINT        NOT NULL,
    [MasterCompanyId]    INT           NOT NULL,
    [ApiName]            VARCHAR (100) NOT NULL,
    [TotalCalls]         BIGINT        CONSTRAINT [DF_EmployeeApiUsage_TotalCalls] DEFAULT ((0)) NOT NULL,
    [SuccessCalls]       BIGINT        CONSTRAINT [DF_EmployeeApiUsage_SuccessCalls] DEFAULT ((0)) NOT NULL,
    [FailedCalls]        BIGINT        CONSTRAINT [DF_EmployeeApiUsage_FailedCalls] DEFAULT ((0)) NOT NULL,
    [LastStatusCode]     INT           NULL,
    [LastCalledDate]     DATETIME2 (7) NULL,
    [CreatedDate]        DATETIME2 (7) CONSTRAINT [DF_EmployeeApiUsage_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_EmployeeApiUsage] PRIMARY KEY CLUSTERED ([EmployeeApiUsageId] ASC),
    CONSTRAINT [UQ_EmployeeApiUsage_EmployeeId_ApiName] UNIQUE NONCLUSTERED ([EmployeeId] ASC, [ApiName] ASC)
);

