CREATE TABLE [dbo].[CMM] (
    [CMMId]           BIGINT         NOT NULL,
    [CMMAlphabets]    VARCHAR (30)   NOT NULL,
    [ServiceLetters]  VARCHAR (30)   NULL,
    [ServiceBulletin] VARCHAR (30)   NULL,
    [RevisionInfo]    VARCHAR (30)   NULL,
    [PublicationDate] DATETIME2 (7)  NULL,
    [MasterCompanyId] INT            NOT NULL,
    [Comments]        VARCHAR (500)  NULL,
    [URL]             NVARCHAR (512) NULL,
    [CreatedBy]       VARCHAR (256)  NULL,
    [UpdatedBy]       VARCHAR (256)  NULL,
    [CreatedDate]     DATETIME2 (7)  NULL,
    [UpdatedDate]     DATETIME2 (7)  NULL,
    [IsActive]        BIT            NULL,
    [IsDelete]        BIT            NULL,
    CONSTRAINT [PK_CMM] PRIMARY KEY CLUSTERED ([CMMId] ASC),
    CONSTRAINT [FK_CMM_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);

