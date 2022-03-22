CREATE TABLE [dbo].[WorkScope] (
    [WorkScopeId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkScopeCode]    VARCHAR (30)   NOT NULL,
    [Description]      VARCHAR (500)  NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [WorkScope_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [WorkScope_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            CONSTRAINT [WorkScope_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [WorkScope_DC_Delete] DEFAULT ((0)) NOT NULL,
    [WorkScopeCodeNew] VARCHAR (50)   NULL,
    [ConditionId]      INT            NULL,
    CONSTRAINT [PK_WorkScope] PRIMARY KEY CLUSTERED ([WorkScopeId] ASC),
    CONSTRAINT [FK_WorkScope_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_WorkScope] UNIQUE NONCLUSTERED ([WorkScopeCode] ASC, [MasterCompanyId] ASC)
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_WorkScope]

   ON  [dbo].[WorkScope]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO WorkScopeAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END