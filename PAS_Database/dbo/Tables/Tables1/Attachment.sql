CREATE TABLE [dbo].[Attachment] (
    [AttachmentId]    BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleId]        INT           NOT NULL,
    [ReferenceId]     BIGINT        NULL,
    [MasterCompanyId] INT           NOT NULL,
    [CreatedBy]       VARCHAR (256) NULL,
    [CreatedDate]     DATETIME2 (7) CONSTRAINT [DF_Attachment_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]       VARCHAR (256) NULL,
    [UpdatedDate]     DATETIME2 (7) CONSTRAINT [DF_Attachment_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT           CONSTRAINT [DF_Attachment_IsActive] DEFAULT ((1)) NULL,
    [IsDeleted]       BIT           CONSTRAINT [DF_Attachment_IsDeleted] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_Attachment] PRIMARY KEY CLUSTERED ([AttachmentId] ASC),
    CONSTRAINT [FK_Attachment_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId])
);


GO




CREATE TRIGGER [dbo].[Trg_AttachmentAudit] ON [dbo].[Attachment]

   AFTER INSERT,DELETE,UPDATE  

AS   

BEGIN  

  

	INSERT INTO [dbo].[AttachmentAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



  

END