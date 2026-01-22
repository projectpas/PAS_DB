CREATE TABLE [dbo].[NewLibraryCMM] (
    [PubType]                NVARCHAR (50)  NULL,
    [Location]               NVARCHAR (500) NULL,
    [PubID]                  NVARCHAR (500) NULL,
    [PartNumber]             NVARCHAR (500) NULL,
    [PublicationDescription] NVARCHAR (500) NULL,
    [PublishedBy]            NVARCHAR (500) NULL,
    [RevisionNum]            NVARCHAR (50)  NULL,
    [RevisionDate]           DATE           NULL,
    [DoNotMap]               NVARCHAR (50)  NULL,
    [VerifyBy]               NVARCHAR (50)  NULL,
    [VerifyDate]             NVARCHAR (50)  NULL,
    [InsertedPubId]          BIGINT         NULL
);

