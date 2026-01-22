CREATE TABLE [dbo].[ExportClassification] (
    [ExportClassificationId] TINYINT       IDENTITY (1, 1) NOT NULL,
    [Description]            VARCHAR (100) NOT NULL,
    CONSTRAINT [PK_ExportClassification] PRIMARY KEY CLUSTERED ([ExportClassificationId] ASC)
);

