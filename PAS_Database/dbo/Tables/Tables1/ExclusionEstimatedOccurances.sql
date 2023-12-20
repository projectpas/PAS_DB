CREATE TABLE [dbo].[ExclusionEstimatedOccurances] (
    [Id]          INT           IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50)  CONSTRAINT [DF__Exclusion__Creat__7524215F] DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME      NOT NULL,
    [UpdatedBy]   VARCHAR (50)  CONSTRAINT [DF__Exclusion__Updat__76184598] DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME      CONSTRAINT [DF__Exclusion__Updat__770C69D1] DEFAULT (NULL) NULL,
    [IsDeleted]   BIT           CONSTRAINT [DF__Exclusion__IsDel__78008E0A] DEFAULT (NULL) NULL,
    [Name]        VARCHAR (256) NULL,
    CONSTRAINT [PK__Exclusio__3214EC07E6DC0EE0] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ExclusionEstimatedOccurancesAudit]

   ON  [dbo].[ExclusionEstimatedOccurances]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO ExclusionEstimatedOccurancesAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END