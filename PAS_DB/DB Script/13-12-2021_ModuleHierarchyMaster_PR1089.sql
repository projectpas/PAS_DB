IF NOT EXISTS(select * from ModuleHierarchyMaster where PermissionConstant='Asset_Aircraft')
BEGIN
INSERT INTO [dbo].[ModuleHierarchyMaster]
           ([Name] ,[ParentId],[IsPage],[DisplayOrder],[IsMenu],[RouterLink],[PermissionConstant]
           ,[IsCreateMenu],[ModuleId],[ListParentId])
VALUES	('View Aircraft Info',122,1,2,0,'/assetmodule/assetpages/app-edit-asset','Asset_Aircraft',0,120,121)
   END        
GO
-------------------------------------------------------------------------------------------
IF NOT EXISTS(select * from ModuleHierarchyMaster where PermissionConstant='Asset_Atachapter')
BEGIN
INSERT INTO [dbo].[ModuleHierarchyMaster]
           ([Name] ,[ParentId],[IsPage],[DisplayOrder],[IsMenu],[RouterLink],[PermissionConstant]
           ,[IsCreateMenu],[ModuleId],[ListParentId])
VALUES	('View ATA Chapter',122,1,3,0,'/assetmodule/assetpages/app-edit-asset','Asset_Atachapter',0,120,121)
  END         
GO
------------------------------------------------------------------------
Update ModuleHierarchyMaster set DisplayOrder=4 where PermissionConstant='Asset_Calibration' and name='Calibration'
Update ModuleHierarchyMaster set DisplayOrder=5 where PermissionConstant='Asset_MaintenanceAndWarranty' and name='Maintenance & Warranty'


