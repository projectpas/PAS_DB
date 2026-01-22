CREATE TABLE [dbo].[Site] (
    [SiteId]          BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (50)   NOT NULL,
    [AddressId]       BIGINT         NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Site_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Site_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_Site_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_Site_Delete] DEFAULT ((0)) NOT NULL,
    [LegalEntityId]   BIGINT         NOT NULL,
    [IsDefault]       BIT            NULL,
    CONSTRAINT [PK_Site] PRIMARY KEY CLUSTERED ([SiteId] ASC),
    CONSTRAINT [FK_Site_Address] FOREIGN KEY ([AddressId]) REFERENCES [dbo].[Address] ([AddressId]),
    CONSTRAINT [FK_Site_LegalEntity] FOREIGN KEY ([LegalEntityId]) REFERENCES [dbo].[LegalEntity] ([LegalEntityId]),
    CONSTRAINT [FK_Site_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Site] UNIQUE NONCLUSTERED ([Name] ASC, [MasterCompanyId] ASC)
);


GO
----------------------------------------------

CREATE   TRIGGER [dbo].[Trg_Site]

   ON  [dbo].[Site]

   AFTER INSERT,UPDATE

AS 
BEGIN

	DECLARE @AddressId BIGINT,@LegalEntityId BIGINT,@Line1 VARCHAR(50),@Line2 VARCHAR(50),
	@City VARCHAR(50),@StateOrProvince VARCHAR(50),@PostalCode VARCHAR(20),@Country VARCHAR(50),@LegalEntity VARCHAR(50)

	SELECT @AddressId=AddressId,@LegalEntityId=LegalEntityId FROM INSERTED

	SELECT @Line1=Line1,@Line2=Line2,@City=City,@StateOrProvince=StateOrProvince,@PostalCode=PostalCode,@Country=nice_name
	FROM Address AD
	JOIN [dbo].[Countries] C WITH(NOLOCK) ON AD.CountryId=C.countries_id
	WHERE AddressId=@AddressId

	SELECT @LegalEntity=Name FROM LegalEntity WHERE LegalEntityId=@LegalEntityId

	INSERT INTO [dbo].[SiteAudit] 
	 (SiteId,Name,AddressId,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate ,IsActive,IsDeleted,LegalEntityId ,Line1,Line2,City,StateOrProvince,PostalCode,Country,LegalEntity,IsDefault)
	 (SELECT SiteId,Name,AddressId,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate, IsActive,IsDeleted,LegalEntityId  ,@Line1,@Line2,@City,@StateOrProvince,@PostalCode,@Country,@LegalEntity,IsDefault FROM INSERTED )

	SET NOCOUNT ON;

END