CREATE TABLE [dbo].[EmployeeApiRequestLog] (
    [EmployeeApiRequestLogId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmployeeId]              BIGINT         NULL,
    [MasterCompanyId]         INT            NULL,
    [ClientId]                VARCHAR (100)  NULL,
    [TokenId]                 VARCHAR (50)   NULL,
    [HttpMethod]              VARCHAR (10)   NOT NULL,
    [RequestPath]             VARCHAR (500)  NOT NULL,
    [QueryString]             VARCHAR (1000) NULL,
    [StatusCode]              INT            NOT NULL,
    [DurationMs]              INT            NOT NULL,
    [IpAddress]               VARCHAR (50)   NULL,
    [UserAgent]               NVARCHAR (500) NULL,
    [CreatedDate]             DATETIME2 (7)  CONSTRAINT [DF_EmployeeApiRequestLog_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    CONSTRAINT [PK_EmployeeApiRequestLog] PRIMARY KEY CLUSTERED ([EmployeeApiRequestLogId] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_EmployeeApiRequestLog_EmployeeId_CreatedDate]
    ON [dbo].[EmployeeApiRequestLog]([EmployeeId] ASC, [CreatedDate] ASC);

