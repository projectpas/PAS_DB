CREATE TABLE [dbo].[DMAction] (
    [DMActionId]  TINYINT      IDENTITY (1, 1) NOT NULL,
    [Description] VARCHAR (50) NULL,
    CONSTRAINT [PK_DMAction] PRIMARY KEY CLUSTERED ([DMActionId] ASC)
);

