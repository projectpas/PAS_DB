
  
-- EXEC AutoCompleteDropdownsBasedontwoTables  'AssetIntangibleAttributeType','AssetIntangibleType','AssetIntangibleTypeId','AssetIntangibleName','',1,'20' ,1,1  
    
CREATE PROCEDURE [dbo].[AutoCompleteDropdownsBasedontwoTables]    
@TableName1 VARCHAR(50) = Null,  
@TableName2 VARCHAR(50)= Null,  
@Parameter1 VARCHAR(50)= Null,    
@Parameter2 VARCHAR(100)= Null,    
@Parameter3 VARCHAR(50)= Null,    
@Parameter4 bit = true,    
@Count VARCHAR(10) = '0',    
@Idlist VARCHAR(max) = '0'  ,
@masterCompanyID VARCHAR(10)
    
AS    
 BEGIN   
 
   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
   SET NOCOUNT ON
   BEGIN TRY 
   
   DECLARE @Sql NVARCHAR(MAX);     
   IF(@Count = '0')     
     BEGIN    
     set @Count='20';     
   END    
    
  CREATE TABLE #TempTable(    
   Value BIGINT,    
   Label VARCHAR(MAX))      
           
   IF(@Parameter4=1)    
    BEGIN    
     SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST (T1. '+@Parameter1+' AS BIGINT) As Value,CAST (T2. '+ @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName1+     
          ' T1 inner join '+@TableName2+' T2 on T1.'+@Parameter1+'= T2.'+@Parameter1+'  WHERE T1.MasterCompanyId=CAST ('+@masterCompanyID+' AS INT) and CAST (T1.'+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
            
        INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST (T1.'+@Parameter1+' AS BIGINT) As Value,CAST (T2.'+ @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName1+     
          ' T1 inner join '+@TableName2+' T2 on T1.'+@Parameter1+'= T2.'+@Parameter1+' WHERE T1.MasterCompanyId=CAST ('+@masterCompanyID+' AS INT) and T1.IsActive=1 AND ISNULL(T2.IsDeleted,0)=0 AND CAST (T2.'+@Parameter2+' AS VARCHAR) !='''' AND T2.'+@Parameter2+'  LIKE '''+ @Parameter3 +'%''      
          ORDER BY Label'    
    END    
   ELSE    
    BEGIN    
     SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST (T1.'+@Parameter1+' AS BIGINT) As Value,CAST ( T2.'+ @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName1+     
          ' T1 inner join '+@TableName2+' T2 on T1.'+@Parameter1+'= T2.'+@Parameter1+' WHERE T1.MasterCompanyId=CAST ('+@masterCompanyID+' AS INT) and CAST (T1.'+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
             
          INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST (T1.'+@Parameter1+' AS BIGINT) As Value,CAST (T2.'+ @Parameter2+  ' AS VARCHAR) AS Label FROM dbo.' + @TableName1+     
          ' T1 inner join '+@TableName2+' T2 on T1.'+@Parameter1+'= T2.'+@Parameter1+' WHERE T1.MasterCompanyId=CAST ('+@masterCompanyID+' AS INT) and T1.IsActive=1 AND ISNULL(T1.IsDeleted,0)=0 AND CAST ( T2.'+@Parameter2+' AS VARCHAR) !='''' AND T2.'+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''  ORDER BY Label';    
    END    
      
  PRINT @Sql    
  EXEC sp_executesql @Sql;    
  SELECT DISTINCT * FROM #TempTable  order by Label;  
  DROP Table #TempTable
 
 END TRY
 BEGIN CATCH 
			-- temp table drop
			IF OBJECT_ID(N'tempdb..#TempTable') IS NOT NULL
			BEGIN
				 DROP Table #TempTable  
			END			
	        DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name() 
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsBasedontwoTables'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TableName1, '') as varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@TableName2, '') as varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@Parameter1, '') as varchar(100)) 
			   + '@Parameter4 = ''' + CAST(ISNULL(@Parameter2, '') as varchar(100))  
			   + '@Parameter5 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))  
			   + '@Parameter6 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100))  			  
			   + '@Parameter7 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			   + '@Parameter8 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100)) 
			   + '@Parameter9 = ''' + CAST(ISNULL(@masterCompanyID, '') as varchar(100))  			                                           
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