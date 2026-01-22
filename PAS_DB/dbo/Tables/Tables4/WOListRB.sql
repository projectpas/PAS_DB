CREATE TABLE [dbo].[WOListRB] (
    [WOListRBId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)   NOT NULL,
    [Description]     VARCHAR (256)  NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_WOListRB_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_WOListRB_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_WOListRB_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_WOListRB_IsDeleted] DEFAULT ((0)) NOT NULL,
    [WOListRBType]    INT            NULL,
    CONSTRAINT [PK_WOListRB] PRIMARY KEY CLUSTERED ([WOListRBId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WOListRBAudit]

   ON  [dbo].[WOListRB]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO WOListRBAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END