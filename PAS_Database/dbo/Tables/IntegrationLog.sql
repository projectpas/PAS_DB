CREATE TABLE [dbo].[IntegrationLog] (
    [IntegrationLogId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [UserName]            VARCHAR (100)  NULL,
    [Password]            NVARCHAR (50)  NULL,
    [PartNumber]          VARCHAR (100)  NULL,
    [ConditionIds]        VARCHAR (MAX)  NULL,
    [IntegrationId]       INT            NULL,
    [IntegrationResponse] NVARCHAR (MAX) NULL,
    [ErrorMessage]        NVARCHAR (MAX) NULL,
    [MasterCompanyId]     INT            NOT NULL,
    [CreatedBy]           VARCHAR (256)  NOT NULL,
    [UpdatedBy]           VARCHAR (256)  NULL,
    [CreatedDate]         DATETIME2 (7)  CONSTRAINT [DF_IntegrationLog_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]         DATETIME2 (7)  CONSTRAINT [DF_IntegrationLog_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsDeleted]           BIT            CONSTRAINT [DF_IntegrationLog_IsDeleted] DEFAULT ((0)) NULL,
    [IsActive]            BIT            CONSTRAINT [DF_IntegrationLog_IsActive] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_IntegrationLog] PRIMARY KEY CLUSTERED ([IntegrationLogId] ASC)
);

