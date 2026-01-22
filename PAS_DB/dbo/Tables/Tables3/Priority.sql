CREATE TABLE [dbo].[Priority] (
    [PriorityId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [Description]     VARCHAR (100)  NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Priority_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Priority_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Priority_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Priority_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Priority] PRIMARY KEY CLUSTERED ([PriorityId] ASC),
    CONSTRAINT [FK_Priority_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Priority] UNIQUE NONCLUSTERED ([Description] ASC, [MasterCompanyId] ASC)
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_Priority]

   ON  [dbo].[Priority]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO PriorityAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END