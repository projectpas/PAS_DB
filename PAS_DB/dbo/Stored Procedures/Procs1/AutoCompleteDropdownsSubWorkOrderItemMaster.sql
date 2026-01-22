/*************************************************************           
 ** File:   [AutoCompleteDropdownsSubWorkOrderItemMaster]           
 ** Author:   HEMANT SALIYA
 ** Description: This stored procedure is used retrieve work Order Item Master List for Auto complete Dropdown List    
 ** Purpose:         
 ** Date:   01/07/2022      
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    01/07/2022   HEMANT SALIYA		Created
    2    08/09/2024   Devendra Shekh	Updated for Add Kit Changes
     
--EXEC [AutoCompleteDropdownsSubWorkOrderItemMaster] '',20,'108,109,11',1
EXEC [AutoCompleteDropdownsSubWorkOrderItemMaster] '',20,'',335
**************************************************************/

CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsSubWorkOrderItemMaster]
@StartWith VARCHAR(50),
@Count VARCHAR(10) = '0',
@Idlist VARCHAR(max) = '0',
@SubWOPartNoId BIGINT

AS
	BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
    SET NOCOUNT ON
	BEGIN TRY
				IF(@Count = '0') 
				   BEGIN
				   SET @Count='20';	
				END	

				SELECT DISTINCT TOP 20 
					IM.ItemMasterId AS Value, 
					im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = WOM.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS Partnumber,
					IM.partnumber AS Label
				FROM dbo.ItemMaster IM WITH(NOLOCK) 	
					JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId
				WHERE (IM.IsActive=1 AND ISNULL(IM.IsDeleted,0) = 0  AND WOM.SubWOPartNoId = @SubWOPartNoId AND (IM.partnumber LIKE @StartWith + '%' OR IM.partnumber  LIKE '%' + @StartWith + '%'))
				UNION
				SELECT DISTINCT TOP 20 
					IM.ItemMasterId AS Value,
					im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = WOM.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS Partnumber,
					IM.partnumber AS Label
				FROM dbo.ItemMaster IM WITH(NOLOCK) 	
					JOIN dbo.SubWorkOrderMaterialsKit WOM WITH(NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId
					JOIN dbo.SubWorkOrderMaterialsKitMapping WOMKM WITH (NOLOCK) ON WOMKM.SubWorkOrderMaterialsKitMappingId = WOM.SubWorkOrderMaterialsKitMappingId
				WHERE (IM.IsActive=1 AND ISNULL(IM.IsDeleted,0) = 0  AND WOM.SubWOPartNoId = @SubWOPartNoId AND (IM.partnumber LIKE @StartWith + '%' OR IM.partnumber  LIKE '%' + @StartWith + '%')) 
				UNION     
				SELECT DISTINCT TOP 20 
					IM.ItemMasterId AS Value, 
					im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = WOM.MasterCompanyId) > 1 then ' - '+ im.ManufacturerName ELSE '' END) AS Partnumber,
					IM.partnumber AS Label
				FROM dbo.ItemMaster IM WITH(NOLOCK) 	
					JOIN dbo.SubWorkOrderMaterials WOM WITH(NOLOCK) ON WOM.ItemMasterId = IM.ItemMasterId
				WHERE IM.ItemMasterId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
				ORDER BY Label			
		END TRY    
		BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'AutoCompleteDropdownsSubWorkOrderItemMaster'               
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@SubWOPartNoId, '') as varchar(100))			  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH	
END