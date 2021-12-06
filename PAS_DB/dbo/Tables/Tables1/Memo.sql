CREATE TABLE [dbo].[Memo] (
    [MemoId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [MemoCode]        VARCHAR (50)   NOT NULL,
    [Description]     NVARCHAR (MAX) NULL,
    [ModuleId]        INT            NOT NULL,
    [ReferenceId]     BIGINT         NOT NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Memo_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Memo_DC_Delete] DEFAULT ((0)) NOT NULL,
    [WorkOrderPartNo] BIGINT         NULL,
    CONSTRAINT [PK_Memo] PRIMARY KEY CLUSTERED ([MemoId] ASC),
    CONSTRAINT [FK_Memo_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Memo_Module] FOREIGN KEY ([ModuleId]) REFERENCES [dbo].[Module] ([ModuleId])
);


GO


CREATE TRIGGER [dbo].[Trg_MemoAudit]

   ON  [dbo].[Memo]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[MemoAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END