CREATE TABLE [dbo].[Warehouse] (
    [WarehouseId]     BIGINT         IDENTITY (1, 1) NOT NULL,
    [Name]            VARCHAR (100)  NOT NULL,
    [SiteId]          BIGINT         NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Warehouse_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Warehouse_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [D_Warehouse_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [D_Warehouse_Delete] DEFAULT ((0)) NOT NULL,
    [WarehouseCode]   VARCHAR (200)  NULL,
    CONSTRAINT [PK_Warehouse] PRIMARY KEY CLUSTERED ([WarehouseId] ASC),
    CONSTRAINT [FK_Warehouse_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [FK_Warehouse_Site] FOREIGN KEY ([SiteId]) REFERENCES [dbo].[Site] ([SiteId]),
    CONSTRAINT [Unique_Warehouse] UNIQUE NONCLUSTERED ([Name] ASC, [SiteId] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_WarehouseAudit] ON [dbo].[Warehouse]

   AFTER INSERT,UPDATE  

AS   

BEGIN  

  

 DECLARE  @SiteId BIGINT, @AddressId BIGINT,@LegalEntityId BIGINT,@Line1 VARCHAR(50),@Line2 VARCHAR(50),

	@City VARCHAR(50),@StateOrProvince VARCHAR(50),@PostalCode VARCHAR(20),

	@Country VARCHAR(50),@LegalEntity VARCHAR(50),@SiteName VARCHAR(50)





	SELECT @SiteId=SiteId FROM INSERTED

	SELECT @AddressId=AddressId,@LegalEntityId=LegalEntityID,@SiteName=Name FROM Site WHERE SiteId=@SiteId





	SELECT @Line1=Line1,@Line2=Line2,@City=City,@StateOrProvince=StateOrProvince,@PostalCode=PostalCode,@Country=nice_name

	FROM Address AD

	JOIN Countries C ON AD.CountryId=C.countries_id

	WHERE AddressId=@AddressId



	SELECT @LegalEntity=Name FROM LegalEntity WHERE LegalEntityId=@LegalEntityId

	





	INSERT INTO [dbo].[WareHouseAudit] 

	 (WarehouseId,Name,SiteId,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate ,IsActive,IsDeleted,Line1,Line2,City,StateOrProvince,PostalCode,Country,LegalEntity,SiteName)

	( SELECT WarehouseId,Name,SiteId,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate, IsActive,IsDeleted,@Line1,@Line2,@City,@StateOrProvince,@PostalCode,@Country,@LegalEntity,@SiteName FROM INSERTED )

  

 SET NOCOUNT ON;  

  

END