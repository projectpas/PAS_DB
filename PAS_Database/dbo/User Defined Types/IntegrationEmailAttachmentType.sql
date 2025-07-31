CREATE TYPE [dbo].[IntegrationEmailAttachmentType] AS TABLE (
    [IntegrationEmailAttachmentID] BIGINT         NULL,
    [IntegrationEmailID]           BIGINT         NULL,
    [AttachmentName]               NVARCHAR (320) NOT NULL,
    [AttachmentPath]               NVARCHAR (320) NOT NULL);

