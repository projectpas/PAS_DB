/************************************************************             
 ** File:   [ModuleHierarchyMaster]            
 ** Author:  Seema Mansuri  
 ** Description: Insert record in   ModuleHierarchyMaster for  OEMCrossReferenceList  
 ** Purpose:           
 ** Date:   19/12/2023             


 eXEC dbo].[ModuleHierarchyMaster]  213

 ************************/


/****** Object:  StoredProcedure [dbo].[OEMCrossReferenceList]    Script Date: 12/19/2023 1:08:03 PM ******/


IF NOT EXISTS 
(SELECT 1 FROM  [dbo].[ModuleHierarchyMaster] WHERE [Name] = 'OEM Cross Reference')
BEGIN
INSERT INTO [dbo].[ModuleHierarchyMaster]
           (
		   [Name]
           ,[ParentId]
           ,[IsPage]
           ,[DisplayOrder]          
           ,[IsMenu]         
           ,[RouterLink]
           ,[PermissionConstant]
           ,[IsCreateMenu]
           ,[ModuleId]
		   )
          
     VALUES
           (
		   'OEM Cross Reference'
           ,(SELECT ID FROM ModuleHierarchyMaster WHERE NAME='Item Master'
AND ParentId=(SELECT Id  FROM ModuleHierarchyMaster WHERE Name='Inventory Management'))
           ,1
           ,11      
           ,1        
           ,'/itemmastersmodule/itemmasterpages/item-master-oem-list'
           ,'OEMCrossReference'
           ,0
           ,(SELECT ID FROM ModuleHierarchyMaster WHERE NAME='Item Master'
AND ParentId=(SELECT Id  FROM ModuleHierarchyMaster WHERE Name='Inventory Management'))
		   )         
END


