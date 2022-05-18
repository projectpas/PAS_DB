CREATE TABLE [dbo].[MasterCompany] (
    [MasterCompanyId]          INT           IDENTITY (1, 1) NOT NULL,
    [MasterCompanyCode]        VARCHAR (100) NULL,
    [CompanyName]              VARCHAR (500) NULL,
    [TaxId]                    VARCHAR (15)  NULL,
    [EmailAddress]             VARCHAR (50)  NULL,
    [Address]                  VARCHAR (100) NULL,
    [CreatedBy]                VARCHAR (256) NULL,
    [UpdatedBy]                VARCHAR (256) NULL,
    [CreatedDate]              DATETIME2 (7) CONSTRAINT [DF_MasterCompany_CreatedDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]              DATETIME2 (7) CONSTRAINT [DF_MasterCompany_UpdatedDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]                 BIT           CONSTRAINT [DF_MasterCompany_IsActive] DEFAULT ((1)) NULL,
    [ManagementStructureLevel] INT           NULL,
    [companylogo]              VARCHAR (256) NULL,
    [Line1]                    VARCHAR (50)  NULL,
    [Line2]                    VARCHAR (50)  NULL,
    [City]                     VARCHAR (50)  NULL,
    [StateOrProvince]          VARCHAR (50)  NULL,
    [PostalCode]               VARCHAR (20)  NULL,
    [CountryId]                SMALLINT      NULL,
    [PhoneNumber]              VARCHAR (30)  NULL,
    [TimeZoneCode]             VARCHAR (50)  NULL,
    CONSTRAINT [PK_MasterCompany] PRIMARY KEY CLUSTERED ([MasterCompanyId] ASC)
);






GO


CREATE TRIGGER [dbo].[Trg_MasterCompanyAudit]

   ON  [dbo].[MasterCompany]

   AFTER INSERT,DELETE,UPDATE

AS

BEGIN

	INSERT INTO MasterCompanyAudit

	SELECT * FROM INSERTED

	SET NOCOUNT ON;

END
GO


CREATE TRIGGER [dbo].[Trg_DefaultCondition]

   ON  [dbo].[MasterCompany]

   AFTER INSERT

AS 

BEGIN

	DECLARE @MasterCompanyId INT;

    SELECT @MasterCompanyId = INSERTED.MasterCompanyId       

    FROM INSERTED;



	INSERT INTO Condition VALUES('BENCH CHECK','',GETDATE(),GETDATE(),1,@MasterCompanyId, 'Auto Script','Auto Script',0,1,'BENCH CHECK');

	INSERT INTO Condition VALUES('OVERHAUL','',GETDATE(),GETDATE(),1,@MasterCompanyId, 'Auto Script','Auto Script',0,2,'OVERHAUL');

	INSERT INTO Condition VALUES('REPAIR','',GETDATE(),GETDATE(),1,@MasterCompanyId, 'Auto Script','Auto Script',0,3,'REPAIR');



	SET NOCOUNT ON;

END