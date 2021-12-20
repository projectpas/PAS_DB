IF NOT EXISTS(SELECT * FROM AttachmentModule WHERE Name='InventoryMaintenance')
BEGIN
INSERT INTO [dbo].[AttachmentModule]
           ([Name] ,[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
           ,[IsActive],[IsDeleted])
VALUES	('AssetInventoryMaintenance','AssetInventoryMaintenance',0,'Admin', 'Admin',getdate(), Getdate(),1,0)
   END        
GO
-------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM AttachmentModule WHERE Name='InventoryWarranty')
BEGIN
INSERT INTO [dbo].[AttachmentModule]
           ([Name] ,[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
           ,[IsActive],[IsDeleted])
VALUES	('AssetInventoryWarranty','AssetInventoryWarranty',0,'Admin', 'Admin',getdate(), Getdate(),1,0)
   END        
GO
-------------------------------------------------------------------------------------------
IF NOT EXISTS(SELECT * FROM AttachmentModule WHERE Name='AssetInventoryIntangible')
BEGIN
INSERT INTO [dbo].[AttachmentModule]
           ([Name] ,[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate]
           ,[IsActive],[IsDeleted])
VALUES	('AssetInventoryIntangible','AssetInventoryIntangible',0,'Admin', 'Admin',getdate(), Getdate(),1,0)
   END        
GO
-------------------------------------------------------------------------------------------

--Update [AttachmentModule] set Name = 'AssetInventoryWarranty' where name = 'InventoryWarranty'
--Update [AttachmentModule] set Name = 'AssetInventoryMaintenance' where name = 'InventoryMaintenance'