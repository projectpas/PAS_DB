CREATE TABLE [dbo].[DefaultConnectionStringUrl] (
    [DefaultConnectionStringUrlId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [URLPattern]                   VARCHAR (500) NOT NULL,
    [MasterCompanyId]              INT           NOT NULL,
    [CreatedBy]                    VARCHAR (256) NOT NULL,
    [CreatedDate]                  DATETIME2 (7) CONSTRAINT [DF_DefaultConnectionStringUrl_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedBy]                    VARCHAR (256) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7) CONSTRAINT [DF_DefaultConnectionStringUrl_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]                     BIT           CONSTRAINT [DF_DefaultConnectionStringUrl_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT           CONSTRAINT [DF_DefaultConnectionStringUrl_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_DefaultConnectionStringUrl] PRIMARY KEY CLUSTERED ([DefaultConnectionStringUrlId] ASC)
);

