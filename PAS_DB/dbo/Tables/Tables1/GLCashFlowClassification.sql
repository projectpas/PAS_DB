CREATE TABLE [dbo].[GLCashFlowClassification] (
    [GLClassFlowClassificationId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [GLClassFlowClassificationName] VARCHAR (200)  NOT NULL,
    [MasterCompanyId]               INT            NOT NULL,
    [CreatedBy]                     VARCHAR (256)  NOT NULL,
    [UpdatedBy]                     VARCHAR (256)  NOT NULL,
    [CreatedDate]                   DATETIME2 (7)  CONSTRAINT [GLClassFlowClassification_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                   DATETIME2 (7)  CONSTRAINT [GLClassFlowClassification_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                      BIT            CONSTRAINT [GlClassFlowClassification_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                     BIT            CONSTRAINT [GlClassFlowClassification_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Description]                   VARCHAR (100)  NOT NULL,
    [Memo]                          NVARCHAR (MAX) NULL,
    CONSTRAINT [PK_GLClassFlowClassification] PRIMARY KEY CLUSTERED ([GLClassFlowClassificationId] ASC),
    CONSTRAINT [FK_GLClassFlowClassification_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_GLClassFlowClassification] UNIQUE NONCLUSTERED ([GLClassFlowClassificationName] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_GLClassFlowClassification]

   ON  [dbo].[GLCashFlowClassification]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	SET NOCOUNT ON;



	INSERT INTO GLCashFlowClassificationAudit

	SELECT * FROM INSERTED

END