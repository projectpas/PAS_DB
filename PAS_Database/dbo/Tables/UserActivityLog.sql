CREATE TABLE [dbo].[UserActivityLog] (
    [UserActivityLogId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [Request]           VARCHAR (MAX) NULL,
    [Payload]           VARCHAR (MAX) NULL,
    [EmployeeId]        BIGINT        NULL,
    [EmployeeName]      VARCHAR (100) NULL,
    [URL]               VARCHAR (500) NULL,
    [IpAddress]         VARCHAR (50)  NULL,
    [MasterCompanyId]   INT           NULL,
    [TimeStamp]         DATETIME2 (7) CONSTRAINT [DF_UserActivityLog_TimeStamp] DEFAULT (getutcdate()) NULL,
    [CreatedDate]       DATETIME2 (7) NULL,
    [UpdatedDate]       DATETIME2 (7) NULL,
    [CreatedBy]         VARCHAR (100) NULL,
    [UpdatedBy]         VARCHAR (100) NULL,
    [IsDeleted]         BIT           CONSTRAINT [DF_UserActivityLog_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]          BIT           CONSTRAINT [DF_UserActivityLog_IsActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK_UserActivityLog] PRIMARY KEY CLUSTERED ([UserActivityLogId] ASC)
);

