CREATE TABLE [dbo].[TagTypeMapping] (
    [TagTypeMappingId] BIGINT        IDENTITY (1, 1) NOT NULL,
    [ModuleId]         INT           NOT NULL,
    [TagTypeId]        BIGINT        NOT NULL,
    [ReferenceId]      BIGINT        NOT NULL,
    [AttachmentId]     BIGINT        NOT NULL,
    [MasterCompanyId]  INT           NOT NULL,
    [CreatedBy]        VARCHAR (256) NOT NULL,
    [UpdatedBy]        VARCHAR (256) NOT NULL,
    [CreatedDate]      DATETIME2 (7) CONSTRAINT [DF_TagTypeMapping_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7) CONSTRAINT [DF_TagTypeMapping_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT           CONSTRAINT [DF_TagTypeMapping_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT           CONSTRAINT [DF_TagTypeMapping_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_TagTypeMapping] PRIMARY KEY CLUSTERED ([TagTypeMappingId] ASC),
    CONSTRAINT [FK_TagTypeMapping_Attachment] FOREIGN KEY ([AttachmentId]) REFERENCES [dbo].[Attachment] ([AttachmentId]),
    CONSTRAINT [FK_TagTypeMapping_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_TagTypeMapping_TagType] FOREIGN KEY ([TagTypeId]) REFERENCES [dbo].[TagType] ([TagTypeId])
);


GO


CREATE TRIGGER [dbo].[Trg_TagTypeMappingAudit]

   ON  [dbo].[TagTypeMapping]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[TagTypeMappingAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END