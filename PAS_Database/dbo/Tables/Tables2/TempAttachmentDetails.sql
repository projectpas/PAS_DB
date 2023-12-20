CREATE TABLE [dbo].[TempAttachmentDetails] (
    [TempAttachmentDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [FileName]               VARCHAR (500)   NULL,
    [Description]            VARCHAR (500)   NULL,
    [Link]                   VARCHAR (500)   NULL,
    [FileFormat]             VARCHAR (500)   NULL,
    [FileSize]               DECIMAL (10, 2) NULL,
    [FileType]               VARCHAR (500)   NULL,
    [CreatedDate]            DATETIME2 (7)   NOT NULL,
    [UpdatedDate]            DATETIME2 (7)   NOT NULL,
    [CreatedBy]              VARCHAR (256)   NOT NULL,
    [UpdatedBy]              VARCHAR (256)   NOT NULL,
    [IsActive]               BIT             NOT NULL,
    [IsDeleted]              BIT             NOT NULL,
    CONSTRAINT [PK_TempAttachmentDetails] PRIMARY KEY CLUSTERED ([TempAttachmentDetailId] ASC)
);

