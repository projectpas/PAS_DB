CREATE TABLE [dbo].[IntegrationEmail] (
    [IntegrationEmailID] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Subject]            VARCHAR (500)  NOT NULL,
    [EmailBody]          NVARCHAR (MAX) NOT NULL,
    [ToEmail]            NVARCHAR (320) NOT NULL,
    [FromEmail]          NVARCHAR (320) NOT NULL,
    [CC]                 NVARCHAR (320) NULL,
    [BCC]                NVARCHAR (320) NULL,
    [EmailReadBy]        NVARCHAR (320) NULL,
    [ReferenceId]        BIGINT         NOT NULL,
    [ModuleId]           INT            NOT NULL,
    [EmailStatus]        BIT            NULL,
    [HasAttachments]     BIT            NULL,
    [EmailSection]       INT            NOT NULL,
    [ReceivedDate]       DATETIME2 (7)  NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [DF_IntegrationEmail_CreatedDate] DEFAULT (getutcdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [DF_IntegrationEmail_UpdatedDate] DEFAULT (getutcdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_IntegrationEmail_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_IntegrationEmail_IsDeleted] DEFAULT ((0)) NOT NULL,
    [CustomerRfqId]      BIGINT         NULL,
    [IsRead]             BIT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_IntegrationEmail] PRIMARY KEY CLUSTERED ([IntegrationEmailID] ASC),
    CONSTRAINT [FK_IntegrationEmail_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);



