CREATE TABLE [dbo].[ATAChapter] (
    [ATAChapterId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [ATAChapterCode]       VARCHAR (256)  NOT NULL,
    [ATAChapterName]       VARCHAR (256)  NOT NULL,
    [MasterCompanyId]      INT            NOT NULL,
    [Memo]                 NVARCHAR (MAX) NULL,
    [CreatedBy]            VARCHAR (256)  NOT NULL,
    [UpdatedBy]            VARCHAR (256)  NOT NULL,
    [CreatedDate]          DATETIME2 (7)  CONSTRAINT [ATAChapter_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]          DATETIME2 (7)  CONSTRAINT [ATAChapter_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]             BIT            CONSTRAINT [ATAChapter_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]            BIT            CONSTRAINT [ATAChapter_DC_Delete] DEFAULT ((0)) NOT NULL,
    [ATAChapterCategoryId] INT            NOT NULL,
    CONSTRAINT [ATA_Chapter] PRIMARY KEY CLUSTERED ([ATAChapterId] ASC),
    CONSTRAINT [FK_ATAChapter_ATAChapterCategory] FOREIGN KEY ([ATAChapterCategoryId]) REFERENCES [dbo].[ATAChapterCategory] ([ATAChapterCategoryId]),
    CONSTRAINT [FK_ATAChapter_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ATAChapterCode] UNIQUE NONCLUSTERED ([ATAChapterCode] ASC, [MasterCompanyId] ASC),
    CONSTRAINT [Unique_ATAChapterName] UNIQUE NONCLUSTERED ([ATAChapterName] ASC, [MasterCompanyId] ASC)
);


GO




-- =============================================

CREATE TRIGGER [dbo].[Trg_ATAChapter]

   ON  [dbo].[ATAChapter]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	DECLARE @ATAChapterCategoryId BIGINT 

	DECLARE @CategoryName VARCHAR(256)



	SELECT  @ATAChapterCategoryId=ATAChapterCategoryId FROM INSERTED

	SELECT @CategoryName=CategoryName FROM ATAChapterCategory WHERE ATAChapterCategoryId=@ATAChapterCategoryId



	INSERT INTO ATAChapterAudit 

	SELECT *,@CategoryName FROM INSERTED





	SET NOCOUNT ON;



END