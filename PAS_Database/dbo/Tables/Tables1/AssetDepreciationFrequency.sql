CREATE TABLE [dbo].[AssetDepreciationFrequency] (
    [AssetDepreciationFrequencyId] BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]                         VARCHAR (50)   NOT NULL,
    [Description]                  VARCHAR (50)   NOT NULL,
    [Memo]                         NVARCHAR (MAX) NULL,
    [MasterCompanyId]              INT            NOT NULL,
    [CreatedBy]                    VARCHAR (256)  NOT NULL,
    [UpdatedBy]                    VARCHAR (256)  NOT NULL,
    [CreatedDate]                  DATETIME2 (7)  CONSTRAINT [AssetDepreciationFrequency_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]                  DATETIME2 (7)  CONSTRAINT [AssetDepreciationFrequency_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                     BIT            CONSTRAINT [DF_AssetDepreciationFrequency_IsActive] DEFAULT ((1)) NOT NULL,
    [IsDeleted]                    BIT            CONSTRAINT [DF_AssetDepreciationFrequency_IsDeleted] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_AssetDepreciationFrequency] PRIMARY KEY CLUSTERED ([AssetDepreciationFrequencyId] ASC),
    CONSTRAINT [FK_AssetDepreciationFrequency_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_AssetDepreciationFrequency] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO


CREATE TRIGGER [dbo].[Trg_AssetDepreciationFrequency]

   ON  [dbo].[AssetDepreciationFrequency]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	 



	INSERT INTO AssetDepreciationFrequencyAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END