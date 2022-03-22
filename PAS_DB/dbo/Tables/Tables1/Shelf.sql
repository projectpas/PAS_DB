CREATE TABLE [dbo].[Shelf] (
    [ShelfId]         BIGINT         IDENTITY (1, 1) NOT NULL,
    [LocationId]      BIGINT         NOT NULL,
    [Name]            VARCHAR (50)   NOT NULL,
    [Memo]            NVARCHAR (MAX) NULL,
    [MasterCompanyId] INT            NOT NULL,
    [CreatedBy]       VARCHAR (256)  NOT NULL,
    [UpdatedBy]       VARCHAR (256)  NOT NULL,
    [CreatedDate]     DATETIME2 (7)  CONSTRAINT [Shelf_DC_CDate] DEFAULT (getdate()) NOT NULL,
    [UpdatedDate]     DATETIME2 (7)  CONSTRAINT [Shelf_DC_UDate] DEFAULT (getdate()) NOT NULL,
    [IsActive]        BIT            CONSTRAINT [Shelf_DC_Active] DEFAULT ((1)) NOT NULL,
    [IsDeleted]       BIT            CONSTRAINT [Shelf_DC_Delete] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_Shelf] PRIMARY KEY CLUSTERED ([ShelfId] ASC),
    CONSTRAINT [FK_Shelf_Location] FOREIGN KEY ([LocationId]) REFERENCES [dbo].[Location] ([LocationId]),
    CONSTRAINT [FK_Shelf_MasterCompany] FOREIGN KEY ([MasterCompanyId]) REFERENCES [dbo].[MasterCompany] ([MasterCompanyId]),
    CONSTRAINT [Unique_Shelf] UNIQUE NONCLUSTERED ([Name] ASC, [LocationId] ASC, [MasterCompanyId] ASC)
);


GO




CREATE TRIGGER [dbo].[Trg_ShelfAudit] ON [dbo].[Shelf]

   AFTER INSERT,UPDATE  

AS   

BEGIN  



 DECLARE  @LocationId BIGINT, @WareHouseId BIGINT, @SiteId BIGINT, @AddressId BIGINT,@LegalEntityId BIGINT,@Line1 VARCHAR(50),@Line2 VARCHAR(50),

	@City VARCHAR(50),@StateOrProvince VARCHAR(50),@PostalCode VARCHAR(20),

	@Country VARCHAR(50),@LegalEntity VARCHAR(50),@Site VARCHAR(50),@WareHouse VARCHAR(50),@Location VARCHAR(50)





	SELECT @LocationId=LocationId FROM INSERTED

	SELECT @WareHouseId=WarehouseId,@Location=Name FROM Location WHERE LocationId=@LocationId



	SELECT @SiteId=SiteId,@WareHouse=Name FROM Warehouse WHERE WarehouseId=@WareHouseId

	SELECT @AddressId=AddressId,@LegalEntityId=LegalEntityID,@Site=Name FROM Site WHERE SiteId=@SiteId





	SELECT @Line1=Line1,@Line2=Line2,@City=City,@StateOrProvince=StateOrProvince,@PostalCode=PostalCode,@Country=nice_name

	FROM Address AD

	JOIN Countries C ON AD.CountryId=C.countries_id

	WHERE AddressId=@AddressId



	SELECT @LegalEntity=Name FROM LegalEntity WHERE LegalEntityId=@LegalEntityId

	





	INSERT INTO [dbo].[ShelfAudit] 

	 (ShelfId,LocationId, Name,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate ,IsActive,IsDeleted,Line1,Line2,City,StateOrProvince,PostalCode,Country,LegalEntity,Site,Warehouse,SiteId,WareHouseId,Location)

	( SELECT ShelfId,LocationId,Name,Memo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate, IsActive,IsDeleted,@Line1,@Line2,@City,@StateOrProvince,@PostalCode,@Country,@LegalEntity,@Site,@WareHouse,@SiteId,@WareHouseId,@Location FROM INSERTED )



 SET NOCOUNT ON;  



END