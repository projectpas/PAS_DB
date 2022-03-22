CREATE TABLE [dbo].[Appl_ErrorLog] (
    [ErrorLogID]          INT            IDENTITY (1, 1) NOT NULL,
    [SQLUserName]         VARCHAR (300)  NOT NULL,
    [ErrorNumber]         INT            NOT NULL,
    [ErrorSeverity]       INT            NOT NULL,
    [ErrorState]          INT            NOT NULL,
    [ErrorProcedure]      VARCHAR (300)  NOT NULL,
    [ProcedureParameters] VARCHAR (3000) NOT NULL,
    [ErrorLine]           INT            NOT NULL,
    [ErrorMessage]        VARCHAR (300)  NOT NULL,
    [DatabaseName]        VARCHAR (300)  NOT NULL,
    [TimeStamp]           DATETIME       CONSTRAINT [DF_Appl_ErrorLog_TimeStamp] DEFAULT (getdate()) NOT NULL,
    [ModuleName]          VARCHAR (300)  NOT NULL,
    [AdhocComments]       VARCHAR (1000) NOT NULL,
    [RolledBackTranCount] TINYINT        NOT NULL,
    [SPID]                INT            NULL,
    [HostName]            VARCHAR (100)  NULL,
    [ClientAppName]       VARCHAR (300)  NULL,
    [ApplicationName]     VARCHAR (100)  NULL
);

