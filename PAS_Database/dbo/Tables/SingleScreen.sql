CREATE TABLE [dbo].[SingleScreen] (
    [SingleScreenId]                 BIGINT        IDENTITY (1, 1) NOT NULL,
    [Screencode]                     VARCHAR (200) NULL,
    [Title]                          VARCHAR (500) NULL,
    [ListView]                       VARCHAR (500) NULL,
    [ManagementStructure]            BIT           CONSTRAINT [DF_SingleScreen_ManagementStructure] DEFAULT ((0)) NULL,
    [ManagementStructureParent]      VARCHAR (100) NULL,
    [ManagementStructureParentTable] VARCHAR (100) NULL,
    [ManagementStructureTable]       VARCHAR (100) NULL,
    [AuditView]                      VARCHAR (500) NULL,
    CONSTRAINT [PK_SingleScreen] PRIMARY KEY CLUSTERED ([SingleScreenId] ASC)
);

