CREATE TABLE [dbo].[EmailConfigration] (
    [EmailConfigId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [Header]          NVARCHAR (MAX) NOT NULL,
    [Footer]          NVARCHAR (MAX) NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_EmailConfigraton_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_EmailConfigraton_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [DF_EmailConfigraton_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [DF_EmailConfigraton_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_EmailConfigraton] PRIMARY KEY CLUSTERED ([EmailConfigId] ASC)
);


GO






CREATE TRIGGER [dbo].[Trg_EmailConfigrationAudit]

   ON  [dbo].[EmailConfigration]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN

	  INSERT INTO [dbo].[EmailConfigrationAudit]

	  SELECT * FROM INSERTED

	  SET NOCOUNT ON;		

END