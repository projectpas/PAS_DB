/*************************************************************           
 ** File:   [AutoCompleteDropdownsItemMasterKit]           
 ** Author:   Vishal Suthar
 ** Description: This stored procedure is used to search part
 ** Purpose:         
 ** Date:   06/14/2024       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/14/2024   Vishal Suthar Added History
    2    06/14/2024   Vishal Suthar Increased Limit of records from 20 to 50 for Item Master Module
     
-- EXEC AutoCompleteDropdownsItemMasterKit 'ItemMaster','ItemMasterId','PartNumber','',1,'20','0',1
**************************************************************/
CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsItemMasterKit]    
@TableName VARCHAR(50) = null,    
@Parameter1 VARCHAR(50)= null,    
@Parameter2 VARCHAR(100)= null,    
@Parameter3 VARCHAR(50)= null,    
@Parameter4 bit = true,    
@Count VARCHAR(10)=0,    
@Idlist VARCHAR(max)='0',  
@MasterCompanyId int    
AS    
BEGIN
 
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY  

  DECLARE @Sql NVARCHAR(MAX);  
    
  CREATE TABLE #TempTable(    
   Value BIGINT,    
   Label VARCHAR(MAX),
   MasterCompanyId int)      
  
  IF(@Count = '0')     
  BEGIN        
     IF(@Parameter4 = 1)    
     BEGIN 
		  IF(@TableName = 'ItemMaster')
		  BEGIN
			SELECT TOP 50 IM.ItemMasterId as Value, Im.partnumber as PartNumber, 
			im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label,
			IM.MasterCompanyId,im.ManufacturerName As ManufacturerName 
			FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND isSerialized = 1 AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND Im.PartNumber like '%'+ @Parameter3+'%'
		  END		  	 
     END    
     ELSE    
     BEGIN  			
			SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
	                         SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
							 CAST(' + @Parameter2 + ' AS VARCHAR(MAX)) AS Label,
							 MasterCompanyId FROM  dbo.'+@TableName+     
			' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
             
			INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
		          SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
				  CAST(' + @Parameter2 + ' AS VARCHAR(MAX)) AS Label,
				  MasterCompanyId FROM dbo.'+@TableName+     
			' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND isSerialized = 1 AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''';    
     END          
  END
  ELSE    
  BEGIN    
  IF(@Parameter4 = 1)    
  BEGIN 
		IF(@TableName = 'ItemMaster')
		BEGIN
			SELECT TOP 50 IM.ItemMasterId as Value, Im.partnumber as PartNumber, 
			im.partnumber + (CASE WHEN (SELECT COUNT(ISNULL(SD.[ManufacturerId], 0)) FROM [dbo].[ItemMaster]  SD WITH(NOLOCK)  WHERE im.partnumber = SD.partnumber AND SD.MasterCompanyId = @MasterCompanyId) > 1 then ' - '+ IM.ManufacturerName ELSE '' END) AS Label,
			IM.MasterCompanyId, im.ManufacturerName AS ManufacturerName
			FROM dbo.ItemMaster IM WHERE Im.MasterCompanyId = @MasterCompanyId AND isSerialized = 1 AND ISNULL(IsActive,1) = 1 AND ISNULL(IsDeleted,0) = 0 AND Im.PartNumber like '%'+ @Parameter3+'%'
		  
		END		 		  
   END    
   ELSE    
   BEGIN   
     SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
	                         SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,
							 CAST ( '+ @Parameter2+  ' AS VARCHAR(MAX)) AS Label,
							 MasterCompanyId FROM  dbo.'+@TableName+     
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND CAST ( '+@Parameter1+' AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
             
          INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
		          SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,
				  CAST('+ @Parameter2 + ' AS VARCHAR(MAX)) AS Label,
				  MasterCompanyId FROM  dbo.'+@TableName+     
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND isSerialized = 1 AND  IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(MAX)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''';    
    END           
  END
  PRINT @Sql    
  EXEC sp_executesql @Sql;    
  SELECT DISTINCT * FROM #TempTable  WHERE MasterCompanyId = @MasterCompanyId ORDER BY Label     
  DROP Table #TempTable  

END TRY
BEGIN CATCH		
	DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsItemMasterKit'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TableName, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Parameter1, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Parameter2, '') as varchar(100))  
			   + '@Parameter4 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100)) 
			   + '@Parameter6 = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
			   + '@Parameter7 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100)) 
			   + '@Parameter8 = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
			,@ApplicationName VARCHAR(100) = 'PAS'

		-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
		EXEC spLogException @DatabaseName = @DatabaseName
			,@AdhocComments = @AdhocComments
			,@ProcedureParameters = @ProcedureParameters
			,@ApplicationName = @ApplicationName
			,@ErrorLogID = @ErrorLogID OUTPUT;

		RAISERROR (
				'Unexpected Error Occured in the database. Please let the support team know of the error number : %d'
				,16
				,1
				,@ErrorLogID
				)

		RETURN (1);

END CATCH  
END