CREATE TABLE [dbo].[ExpertiseTypes] (
    [Id]          INT          IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50) CONSTRAINT [DF__Expertise__Creat__0A1F3E45] DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME     NOT NULL,
    [UpdatedBy]   VARCHAR (50) CONSTRAINT [DF__Expertise__Updat__0B13627E] DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME     CONSTRAINT [DF__Expertise__Updat__0C0786B7] DEFAULT (NULL) NULL,
    [IsDeleted]   BIT          CONSTRAINT [DF__Expertise__IsDel__0CFBAAF0] DEFAULT (NULL) NULL,
    [Name]        VARCHAR (50) CONSTRAINT [DF__ExpertiseT__Name__0DEFCF29] DEFAULT (NULL) NULL,
    CONSTRAINT [PK__Expertis__3214EC07B5D1F7EE] PRIMARY KEY CLUSTERED ([Id] ASC)
);

