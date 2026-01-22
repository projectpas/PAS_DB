CREATE TABLE [dbo].[SingleScreenFieldDisplayField] (
    [SingleScreenFieldDisplayFieldId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [SingleScreenFieldId]             BIGINT        NULL,
    [DisplayField]                    VARCHAR (100) NULL,
    CONSTRAINT [PK_SingleScreenFieldDisplayField] PRIMARY KEY CLUSTERED ([SingleScreenFieldDisplayFieldId] ASC),
    CONSTRAINT [FK_SingleScreenFieldDisplayField_SingleScreenField] FOREIGN KEY ([SingleScreenFieldId]) REFERENCES [dbo].[SingleScreenField] ([SingleScreenFieldId])
);

