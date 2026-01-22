CREATE TABLE [dbo].[ATASubChapter] (
    [ATASubChapterId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [ATASubChapterCode]    VARCHAR (256)  NOT NULL,
    [Description]          VARCHAR (256)  NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [ATASubSubChapter_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [ATASubChapter_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [ATASubChapter_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [ATASubChapter_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ATAChapterId]         BIGINT         NOT NULL,
    [ATAChapterCategoryId] INT            NOT NULL,
    CONSTRAINT [PK_ATASubChapter] PRIMARY KEY CLUSTERED ([ATASubChapterId] ASC),
    CONSTRAINT [FK_ATASubChapter_ATAChapter] FOREIGN KEY ([ATAChapterId]) REFERENCES [dbo].[ATAChapter] ([ATAChapterId]),
    CONSTRAINT [FK_ATASubChapter_ATAChapterCategory] FOREIGN KEY ([ATAChapterCategoryId]) REFERENCES [dbo].[ATAChapterCategory] ([ATAChapterCategoryId]),
    CONSTRAINT [FK_ATASubChapter_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ATASubChapter] UNIQUE NONCLUSTERED ([ATAChapterId] ASC, [ATASubChapterCode] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_ATASubChapterName] UNIQUE NONCLUSTERED ([ATAChapterId] ASC, [Description] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ATASubChapterAudit]

   ON  [dbo].[ATASubChapter]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	DECLARE @ATAChapterId BIGINT

	DECLARE @ATAChapterCategoryId BIGINT 

	DECLARE @CategoryName VARCHAR(256)

	DECLARE @ATAChapterName VARCHAR(256)



	SELECT @ATAChapterId=ATAChapterID, @ATAChapterCategoryId=ATAChapterCategoryId FROM INSERTED

	SELECT @CategoryName=CategoryName FROM ATAChapterCategory WHERE ATAChapterCategoryId=@ATAChapterCategoryId

	SELECT @ATAChapterName=ATAChapterName FROM ATAChapter WHERE ATAChapterId=@ATAChapterId



	INSERT INTO ATASubChapterAudit

	SELECT *,@ATAChapterName,@CategoryName FROM INSERTED

	SET NOCOUNT ON;



END