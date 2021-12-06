CREATE TABLE [dbo].[PublicationType] (
    [PublicationTypeId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]              VARCHAR (256)  NOT NULL,
    [Description]       VARCHAR (256)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (50)   NOT NULL,
    [CreatedDate]       DATETIME2 (7)  CONSTRAINT [PublicationType_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedBy]         VARCHAR (50)   NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  CONSTRAINT [PublicationType_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]          BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]         BIT            DEFAULT ((0)) NOT NULL,
    PRIMARY KEY CLUSTERED ([PublicationTypeId] ASC),
    CONSTRAINT [FK_PublicationType_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_PublicationType] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




-- =============================================

CREATE TRIGGER [dbo].[Trg_PublicationType]

   ON  [dbo].[PublicationType]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO PublicationTypeAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END