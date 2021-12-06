CREATE TABLE [dbo].[AttachmentDetails] (
    [AttachmentDetailId] BIGINT          IDENTITY (1, 1) NOT NULL,
    [AttachmentId]       BIGINT          NOT NULL,
    [FileName]           VARCHAR (500)   NULL,
    [Description]        VARCHAR (MAX)   NULL,
    [Link]               VARCHAR (500)   NULL,
    [FileFormat]         VARCHAR (500)   NULL,
    [FileSize]           DECIMAL (10, 2) NULL,
    [FileType]           VARCHAR (500)   NULL,
    [CreatedDate]        DATETIME2 (7)   CONSTRAINT [DF_AttachmentDetails_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)   CONSTRAINT [DF_AttachmentDetails_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [CreatedBy]          VARCHAR (256)   NULL,
    [UpdatedBy]          VARCHAR (256)   NULL,
    [IsActive]           BIT             CONSTRAINT [DF_AttachmentDetails_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]          BIT             CONSTRAINT [DF_AttachmentDetails_IsDeleted] DEFAULT ((0)) NULL,
    [Name]               VARCHAR (256)   NULL,
    [Memo]               NVARCHAR (MAX)  NULL,
    [TypeId]             BIGINT          NULL,
    CONSTRAINT [PK_AttachmentDetails] PRIMARY KEY CLUSTERED ([AttachmentDetailId] ASC),
    CONSTRAINT [FK_AttachmentDetails_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId])
);


GO


CREATE TRIGGER [dbo].[Trg_AttachmentDetailsAudit]

   ON  [dbo].[AttachmentDetails]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO [AttachmentDetailsAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END