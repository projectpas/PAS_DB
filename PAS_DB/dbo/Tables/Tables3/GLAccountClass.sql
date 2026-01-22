CREATE TABLE [dbo].[GLAccountClass] (
    [GLAccountClassId]   BIGINT         IDENTITY (1, 1) NOT NULL,
    [GLAccountClassName] VARCHAR (200)  NOT NULL,
    [GLAccountClassMemo] NVARCHAR (MAX) NULL,
    [MasterCompanyId]    INT            NOT NULL,
    [CreatedBy]          VARCHAR (256)  NOT NULL,
    [UpdatedBy]          VARCHAR (256)  NOT NULL,
    [CreatedDate]        DATETIME2 (7)  CONSTRAINT [GLAccountClass_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]        DATETIME2 (7)  CONSTRAINT [GLAccountClass_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]           BIT            CONSTRAINT [DF_GLAccountClass_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]          BIT            CONSTRAINT [DF_GLAccountClass_IsDeleted] DEFAULT ((0)) NOT NULL,
    [SequenceNumber]     INT            DEFAULT ((0)) NULL,
    CONSTRAINT [PK_GLAccountClass] PRIMARY KEY CLUSTERED ([GLAccountClassId] ASC),
    CONSTRAINT [FK_GLAccountClass_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_GLAccountClass] UNIQUE NONCLUSTERED ([GLAccountClassName] ASC, [MasterCompanyId] ASC)
);


GO




-- =============================================

CREATE TRIGGER [dbo].[Trg_GLAccountClassAudit]

   ON  [dbo].[GLAccountClass]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN



INSERT INTO GLAccountClassAudit

SELECT * FROM INSERTED



SET NOCOUNT ON;



END