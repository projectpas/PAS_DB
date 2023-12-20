CREATE TABLE [dbo].[POROCategory] (
    [POROCategoryId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [CategoryName]    VARCHAR (30)   NOT NULL,
    [IsPO]            BIT            CONSTRAINT [POROCategory_DC_IsPO] DEFAULT ((0)) NULL,
    [IsRO]            BIT            CONSTRAINT [POROCategory_DC_IsRO] DEFAULT ((0)) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [DF_POROCategory_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [DF_POROCategory_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [POROCategory_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [POROCategory_DC_Delete] DEFAULT ((0)) NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    PRIMARY KEY CLUSTERED ([POROCategoryId] ASC),
    CONSTRAINT [FK_POROCategory_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_POROCategory] UNIQUE NONCLUSTERED ([CategoryName] ASC, [MasterCompanyId] ASC)
);


GO




----------------------------------

CREATE TRIGGER [dbo].[Trg_POROCategoryAudit]

   ON  [dbo].[POROCategory]

   AFTER INSERT,UPDATE

AS 

BEGIN



	INSERT INTO [dbo].[POROCategoryAudit]

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END