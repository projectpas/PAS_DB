CREATE TABLE [dbo].[PublicationStatuses] (
    [Id]          INT           IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50)  CONSTRAINT [DF__Publicati__Creat__47284C85] DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME      NOT NULL,
    [UpdatedBy]   VARCHAR (50)  CONSTRAINT [DF__Publicati__Updat__481C70BE] DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME      CONSTRAINT [DF__Publicati__Updat__491094F7] DEFAULT (NULL) NULL,
    [IsDeleted]   BIT           CONSTRAINT [DF__Publicati__IsDel__4A04B930] DEFAULT (NULL) NULL,
    [Name]        VARCHAR (256) NULL,
    CONSTRAINT [PK__Publicat__3214EC07D9ED52C8] PRIMARY KEY CLUSTERED ([Id] ASC)
);

