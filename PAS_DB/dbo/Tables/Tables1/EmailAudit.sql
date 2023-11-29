﻿CREATE TABLE [dbo].[EmailAudit] (
    [EmailAuditId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [EmailId]           BIGINT         NOT NULL,
    [EmailTypeId]       BIGINT         NULL,
    [Subject]           VARCHAR (MAX)  NULL,
    [ContactById]       BIGINT         NULL,
    [ContactDate]       DATETIME2 (7)  NOT NULL,
    [EmailBody]         VARCHAR (MAX)  NOT NULL,
    [ToEmail]           VARCHAR (4000) NOT NULL,
    [FromEmail]         VARCHAR (4000) NOT NULL,
    [AttachmentId]      BIGINT         NULL,
    [ModuleId]          INT            NOT NULL,
    [ReferenceId]       BIGINT         NOT NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [BCC]               VARCHAR (100)  NULL,
    [CC]                VARCHAR (100)  NULL,
    [CustomerContactId] BIGINT         CONSTRAINT [DF__EmailAudi__Custo__126C0231] DEFAULT ((0)) NULL,
    [WorkOrderPartNo]   BIGINT         NULL,
    [Type]              INT            NULL,
    [EmailStatus]       BIT            NULL,
    [EmailSentTime]     DATETIME2 (7)  NULL,
    [IsAttach]          BIT            NULL,
    [EmailStatusId]     INT            DEFAULT ('1') NULL,
    [AttemptCount]      BIGINT         NULL,
    CONSTRAINT [PK_EmailAudit] PRIMARY KEY CLUSTERED ([EmailAuditId] ASC)
);





