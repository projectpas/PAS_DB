/*************************************************************           
 ** File:   [AutoCompleteDropdownsItemMasterIsPmaORIsDer]           
 ** Author:   Moin
 ** Description: This stored procedure is used retrieve Item Master List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   12/23/2020        
          
 ** PARAMETERS: @UserType varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/23/2020   Moin Created
     
--EXEC [AutoCompleteDropdownsItemMasterIsPmaORIsDer] '822',1,200,'108,109,11',1
**************************************************************/

CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterIsPmaORIsDer]
@StartWith VARCHAR(50),
@IsActive bit,
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@MasterCompanyId int,
@IsPmaorISDer  varchar(10) 
AS
BEGIN
	  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
      SET NOCOUNT ON
	  BEGIN TRY
		
		IF(@IsPmaorISDer = 'IsPma')
		BEGIN
			DECLARE @Sql NVARCHAR(MAX);	
				IF(@Count = '0') 
				BEGIN
					set @Count = '20';	
				END	
				IF(@IsActive = 1)
				BEGIN		
					SELECT DISTINCT TOP 20 
						Im.ItemMasterId AS Value, 
						Im.partnumber AS Label,
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
					FROM dbo.ItemMaster Im WITH(NOLOCK) 						
					WHERE (Im.IsActive = 1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.IsPma != 1 AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'))    
					UNION     
					SELECT DISTINCT Im.ItemMasterId AS Value, 
						Im.partnumber AS Label,
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
					FROM dbo.ItemMaster Im WITH(NOLOCK) 						
					WHERE im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
					ORDER BY Label				
				END
				ELSE
				BEGIN
					SELECT DISTINCT TOP 20 
						Im.ItemMasterId AS Value, 
						Im.partnumber AS Label,
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
					FROM dbo.ItemMaster Im WITH(NOLOCK) 						
					WHERE Im.IsActive=1 AND ISNULL(Im.IsDeleted, 0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.IsPma != 1 AND Im.partnumber LIKE '%' + @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'
					UNION 
					SELECT DISTINCT TOP 20 
						Im.ItemMasterId AS Value,  
						Im.partnumber AS Label,
						im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
					FROM dbo.ItemMaster Im 	WITH(NOLOCK) 					
					WHERE Im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
					ORDER BY Label	
				END	
		END
		ELSE
		BEGIN
			DECLARE @Sql2 NVARCHAR(MAX);	
				IF(@Count = '0') 
				BEGIN
					   set @Count = '20';	
				END	
				IF(@IsActive = 1)
				BEGIN		
					SELECT DISTINCT TOP 20 
							Im.ItemMasterId AS Value, 
							Im.partnumber AS Label,
							im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
							FROM dbo.ItemMaster Im WITH(NOLOCK) 						
							WHERE (Im.IsActive=1 AND ISNULL(Im.IsDeleted,0)=0 AND IM.MasterCompanyId = @MasterCompanyId AND (Im.partnumber LIKE @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'))    
						   UNION     
					SELECT DISTINCT Im.ItemMasterId AS Value, 
							Im.partnumber AS Label,
							im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
							FROM dbo.ItemMaster Im WITH(NOLOCK) 						
							WHERE im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))    
							ORDER BY Label				
				END
				ELSE
				BEGIN
					SELECT DISTINCT TOP 20 
							Im.ItemMasterId AS Value, 
							Im.partnumber AS Label,
							im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
							FROM dbo.ItemMaster Im 	WITH(NOLOCK) 					
							WHERE Im.IsActive = 1 AND ISNULL(Im.IsDeleted,0) = 0 AND IM.MasterCompanyId = @MasterCompanyId AND Im.partnumber LIKE '%' + @StartWith + '%' OR Im.partnumber  LIKE '%' + @StartWith + '%'
							UNION 
					SELECT DISTINCT TOP 20 
							Im.ItemMasterId AS Value,  
							Im.partnumber AS Label,
							im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = im.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS PartNumber
							FROM dbo.ItemMaster Im 	WITH(NOLOCK) 					
							WHERE Im.ItemMasterId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist, ','))
							ORDER BY Label	
				END	
		END

	  END TRY 
	  BEGIN CATCH   
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsItemMasterIsPmaORIsDer'               
			  ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Count, '') as varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@IsPmaorISDer, '') as varchar(100))  	
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH	
END