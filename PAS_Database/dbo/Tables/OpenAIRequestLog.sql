CREATE TABLE [dbo].[OpenAIRequestLog] (
    [LogId]              BIGINT         IDENTITY (1, 1) NOT NULL,
    [IntegrationEmailID] BIGINT         NULL,
    [RequestType]        VARCHAR (100)  NOT NULL,
    [RequestUrl]         NVARCHAR (500) NOT NULL,
    [RequestBody]        NVARCHAR (MAX) NULL,
    [ResponseStatusCode] VARCHAR (20)   NULL,
    [ResponseBody]       NVARCHAR (MAX) NULL,
    [IsSuccess]          BIT            DEFAULT ((0)) NOT NULL,
    [CreatedDate]        DATETIME2 (7)  DEFAULT (sysutcdatetime()) NOT NULL,
    PRIMARY KEY CLUSTERED ([LogId] ASC)
);

