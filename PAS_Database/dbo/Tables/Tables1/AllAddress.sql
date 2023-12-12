CREATE TABLE [dbo].[AllAddress] (
    [AllAddressId]      BIGINT         IDENTITY (1, 1) NOT NULL,
    [ReffranceId]       BIGINT         NOT NULL,
    [ModuleId]          BIGINT         NOT NULL,
    [UserType]          INT            CONSTRAINT [DF__AllAddres__UserT__543CF2EA] DEFAULT ((0)) NOT NULL,
    [UserTypeName]      VARCHAR (100)  NULL,
    [UserId]            BIGINT         CONSTRAINT [DF__AllAddres__UserI__55311723] DEFAULT ((0)) NOT NULL,
    [UserName]          VARCHAR (256)  NULL,
    [SiteId]            BIGINT         CONSTRAINT [DF__AllAddres__SiteI__56253B5C] DEFAULT ((0)) NOT NULL,
    [SiteName]          VARCHAR (256)  NULL,
    [AddressId]         BIGINT         NOT NULL,
    [IsModuleOnly]      BIT            NOT NULL,
    [IsShippingAdd]     BIT            NOT NULL,
    [ShippingAccountNo] VARCHAR (100)  NULL,
    [Memo]              NVARCHAR (MAX) NULL,
    [ContactId]         BIGINT         CONSTRAINT [DF__AllAddres__Conta__57195F95] DEFAULT ((0)) NOT NULL,
    [ContactName]       VARCHAR (50)   NULL,
    [ContactPhoneNo]    VARCHAR (50)   NULL,
    [Line1]             VARCHAR (50)   NULL,
    [Line2]             VARCHAR (50)   NULL,
    [Line3]             VARCHAR (50)   NULL,
    [City]              VARCHAR (50)   NULL,
    [StateOrProvince]   VARCHAR (50)   NULL,
    [PostalCode]        VARCHAR (20)   NULL,
    [CountryId]         INT            NULL,
    [Country]           VARCHAR (50)   NULL,
    [MasterCompanyId]   INT            NOT NULL,
    [CreatedBy]         VARCHAR (256)  NOT NULL,
    [UpdatedBy]         VARCHAR (256)  NOT NULL,
    [CreatedDate]       DATETIME2 (7)  NOT NULL,
    [UpdatedDate]       DATETIME2 (7)  NOT NULL,
    [IsActive]          BIT            NOT NULL,
    [IsDeleted]         BIT            NOT NULL,
    [IsPrimary]         BIT            CONSTRAINT [DF_AllAddress_IsPrimary] DEFAULT ((0)) NULL,
    CONSTRAINT [PK_AllAddress] PRIMARY KEY CLUSTERED ([AllAddressId] ASC)
);


GO


-- =============================================

CREATE TRIGGER [dbo].[Trg_AllAddressAudit]

   ON  [dbo].[AllAddress]

   AFTER INSERT,DELETE,UPDATE

AS 

BEGIN



	INSERT INTO AllAddressAudit

	SELECT * FROM INSERTED



	SET NOCOUNT ON;



END