CREATE TABLE [dbo].[ConventionType] (
    [Name]             NVARCHAR (50)  NOT NULL,
    [Description]      NVARCHAR (100) NOT NULL,
    [Memo]             NVARCHAR (MAX) NULL,
    [MasterCompanyId]  INT            NOT NULL,
    [CreatedBy]        VARCHAR (256)  NOT NULL,
    [UpdatedBy]        VARCHAR (256)  NOT NULL,
    [CreatedDate]      DATETIME2 (7)  CONSTRAINT [ConventionType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]      DATETIME2 (7)  CONSTRAINT [ConventionType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]         BIT            CONSTRAINT [DF_ConventionType_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]        BIT            CONSTRAINT [DF_ConventionType_IsDeleted] DEFAULT ((0)) NOT NULL,
    [ConventionTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([ConventionTypeId] ASC),
    CONSTRAINT [FK_ConventionType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_ConventionType] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




----------------------------------------------

CREATE TRIGGER [dbo].[Trg_ConventionType]

   ON  [dbo].[ConventionType]

   AFTER INSERT,UPDATE

AS 

BEGIN

	

	INSERT INTO [dbo].[ConventionTypeAudit] 

    SELECT * FROM INSERTED 

	SET NOCOUNT ON;



END