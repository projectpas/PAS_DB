CREATE TABLE [dbo].[AuditLogDisplayColumns] (
    [AuditLogDisplayColumnsId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [TableName]                VARCHAR (128) NOT NULL,
    [ColumnName]               VARCHAR (128) NOT NULL,
    [DisplayName]              VARCHAR (256) NOT NULL,
    [SeqNo]                    INT           NULL,
    [FieldAlign]               INT           NULL,
    PRIMARY KEY CLUSTERED ([AuditLogDisplayColumnsId] ASC)
);

