CREATE TYPE [dbo].[ManualJEUploadType] AS TABLE (
    [GlAccountId]     BIGINT          NULL,
    [AccountCode]     VARCHAR (50)    NULL,
    [AccountName]     VARCHAR (100)   NULL,
    [Debit]           DECIMAL (18, 2) NULL,
    [Credit]          DECIMAL (18, 2) NULL,
    [Description]     VARCHAR (100)   NULL,
    [ReferenceId]     BIGINT          NULL,
    [ReferenceTypeId] INT             NULL,
    [Name]            VARCHAR (100)   NULL,
    [Level1Code]      VARCHAR (50)    NULL,
    [Level2Code]      VARCHAR (50)    NULL,
    [Level3Code]      VARCHAR (50)    NULL,
    [Level4Code]      VARCHAR (50)    NULL,
    [Level5Code]      VARCHAR (50)    NULL,
    [Level6Code]      VARCHAR (50)    NULL,
    [Level7Code]      VARCHAR (50)    NULL,
    [Level8Code]      VARCHAR (50)    NULL,
    [Level9Code]      VARCHAR (50)    NULL,
    [Level10Code]     VARCHAR (50)    NULL);



