CREATE TABLE [dbo].[StklineHistory_Action] (
    [ActionId]    BIGINT         IDENTITY (1, 1) NOT NULL,
    [Type]        VARCHAR (100)  NOT NULL,
    [Template]    NVARCHAR (MAX) NOT NULL,
    [DisplayName] VARCHAR (100)  NULL,
    CONSTRAINT [PK_StklineHistory_Action] PRIMARY KEY CLUSTERED ([ActionId] ASC)
);

