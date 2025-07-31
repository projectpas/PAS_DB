CREATE TABLE [dbo].[IntegrationEmailAttachment] (
    [IntegrationEmailAttachmentID] BIGINT         IDENTITY (1, 1) NOT NULL,
    [IntegrationEmailID]           BIGINT         NOT NULL,
    [AttachmentName]               NVARCHAR (320) NOT NULL,
    [AttachmentPath]               NVARCHAR (320) NOT NULL,
    CONSTRAINT [PK_IntegrationEmailAttachment] PRIMARY KEY CLUSTERED ([IntegrationEmailAttachmentID] ASC)
);

