CREATE TABLE [dbo].[Ranking] (
    [RankingId]       BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Ranking_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_Ranking_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_Ranking_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_Ranking_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Ranking] PRIMARY KEY CLUSTERED ([RankingId] ASC)
);


GO
/***********************************************************************************************/
CREATE   TRIGGER [dbo].[Trg_RankingAudit]

   ON  [dbo].[Ranking]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	INSERT INTO RankingAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END