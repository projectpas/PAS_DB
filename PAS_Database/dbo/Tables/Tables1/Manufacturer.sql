CREATE TABLE [dbo].[Manufacturer] (
    [ManufacturerId]  BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100)  NOT NULL,
    [Comments]        NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Manufacturer_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Manufacturer_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Manufacturer] PRIMARY KEY CLUSTERED ([ManufacturerId] ASC),
    CONSTRAINT [FK_Manufacturer_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Manufacturer] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_Manufacturer]

   ON  [dbo].[Manufacturer]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	SET NOCOUNT ON;



	INSERT INTO ManufacturerAudit

	SELECT * FROM INSERTED

END