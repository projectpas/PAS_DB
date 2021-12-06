CREATE TABLE [dbo].[WorkPerformed] (
    [WorkPerformedId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [WorkPerformedCode] VARCHAR (30)   NOT NULL,
    [Description]       VARCHAR (500)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [WorkPerformed_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [WorkPerformed_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [WorkPerformed_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [WorkPerformed_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_WorkPerformed] PRIMARY KEY CLUSTERED ([WorkPerformedId] ASC),
    CONSTRAINT [FK_WorkPerformed_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_WorkPerformed] UNIQUE NONCLUSTERED ([WorkPerformedCode] ASC, [MasterCompanyId] ASC)
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_WorkPerformed]

   ON  [dbo].[WorkPerformed]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO WorkPerformedAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END