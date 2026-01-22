CREATE TABLE [dbo].[MaterialConditions] (
    [Id]          INT          IDENTITY (1, 1) NOT NULL,
    [CreatedBy]   VARCHAR (50) CONSTRAINT [DF__MaterialC__Creat__10CC3BD4] DEFAULT (NULL) NULL,
    [CreatedDate] DATETIME     CONSTRAINT [DF_MaterialConditions_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]   VARCHAR (50) CONSTRAINT [DF__MaterialC__Updat__11C0600D] DEFAULT (NULL) NULL,
    [UpdatedDate] DATETIME     CONSTRAINT [DF__MaterialC__Updat__12B48446] DEFAULT (getdate()) NULL,
    [IsDeleted]   BIT          CONSTRAINT [DF__MaterialC__IsDel__13A8A87F] DEFAULT ((0)) NULL,
    [Name]        VARCHAR (50) CONSTRAINT [DF__MaterialCo__Name__149CCCB8] DEFAULT (NULL) NULL,
    [IsActive]    BIT          CONSTRAINT [DF_MaterialConditions_IsActive] DEFAULT ((1)) NULL,
    CONSTRAINT [PK__Material__3214EC0711F68067] PRIMARY KEY CLUSTERED ([Id] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_MaterialConditionsAudit]

   ON  [dbo].[MaterialConditions]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MaterialConditionsAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END