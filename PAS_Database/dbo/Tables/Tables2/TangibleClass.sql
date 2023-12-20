CREATE TABLE [dbo].[TangibleClass] (
    [TangibleClassId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [TangibleClassName] VARCHAR (30)   NOT NULL,
    [TangibleClassMemo] VARCHAR (1000) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [TangibleClass_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [TangibleClass_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            CONSTRAINT [TangibleClass_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            CONSTRAINT [TangibleClass_DC_Delete] DEFAULT ((0)) NOT NULL,
    [StatusCode]        VARCHAR (25)   NULL,
    CONSTRAINT [PK_TangibleClass] PRIMARY KEY CLUSTERED ([TangibleClassId] ASC),
    CONSTRAINT [FK_TangibleClass_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_TangibleClass] UNIQUE NONCLUSTERED ([TangibleClassName] ASC, [MasterCompanyId] ASC)
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_TangibleClassAudit]

   ON  [dbo].[TangibleClass]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO TangibleClassAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END