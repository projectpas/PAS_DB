CREATE TABLE [dbo].[LogInLog] (
    [LogId]           BIGINT        IDENTITY (1, 1) NOT NULL,
    [EmployeeId]      BIGINT        NULL,
    [LogInTime]       DATETIME      NULL,
    [LogOutTime]      DATETIME      NULL,
    [IPAddress]       VARCHAR (100) NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NOT NULL,
    [CreatedDate]     DATETIME2 (7) NOT NULL,
    [UpdatedDate]     DATETIME2 (7) NOT NULL
);

