CREATE TABLE [dbo].[TagType] (
    [TagTypeId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [TagType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [TagType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [CTagType_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [TagType_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Description]     VARCHAR (256)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    PRIMARY KEY CLUSTERED ([TagTypeId] ASC),
    CONSTRAINT [FK_TagType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_TagType] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_TagTypeAudit]

   ON  [dbo].[TagType]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[TagTypeAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END