CREATE TABLE [dbo].[GlobalFilter] (
    [AutoId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [ModuleId]        BIGINT         NOT NULL,
    [LabelName]       NVARCHAR (100) NOT NULL,
    [FieldType]       NVARCHAR (50)  NULL,
    [Sequnse]         SMALLINT       NULL,
    [TableName]       NVARCHAR (100) NULL,
    [IDName]          NVARCHAR (50)  NULL,
    [ValueName]       NVARCHAR (50)  NULL,
    [IsRequired]      BIT            DEFAULT ((1)) NULL,
    [IsActive]        BIT            DEFAULT ((1)) NULL,
    [MasterCompanyId] INT            DEFAULT ((0)) NULL,
    [ApplyFilter]     NVARCHAR (200) NULL,
    CONSTRAINT [PK_GlobalFilter] PRIMARY KEY CLUSTERED ([AutoId] ASC)
);

