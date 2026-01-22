CREATE TABLE [dbo].[MaterialUOMs] (
    [Id]          INT          IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50) DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME     CONSTRAINT [DF_MaterialUOMs_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]   VARCHAR (50) DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME     CONSTRAINT [DF__MaterialU__Updat__68F2894D] DEFAULT (getdate()) NULL,
    [IsDeleted]   BIT          CONSTRAINT [DF__MaterialU__IsDel__69E6AD86] DEFAULT ((0)) NULL,
    [Name]        VARCHAR (50) DEFAULT (NULL) NULL,
    [IsActive]    BIT          CONSTRAINT [DF_MaterialUOMs_IsActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK__Material__3214EC0787DCCB08] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_MaterialUOMsAudit]

   ON  [dbo].[MaterialUOMs]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MaterialUOMsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END