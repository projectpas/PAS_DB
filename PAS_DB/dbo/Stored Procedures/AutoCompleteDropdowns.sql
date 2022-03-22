

    
    
--select * from dbo.Employee    
--EXEC AutoCompleteDropdowns 'Employee','EmployeeId','FirstName','sur',1,20,'108,109,11',1    
--select * from dbo.Customer    
--EXEC AutoCompleteDropdowns 'ItemMaster','ItemMasterId','PartNumber','',1,'50'    
--EXEC AutoCompleteDropdowns 'Employee','EmployeeId','FirstName','',1,10    
--EXEC AutoCompleteDropdowns 'AssetStatus','AssetStatusId','Name','',0,200,'12'    
--EXEC AutoCompleteDropdowns 'Customer','CustomerId','Name','',1,'0','0',1    
--EXEC AutoCompleteDropdowns 'MasterParts','MasterPartId','PartNumber','',1,'20','0',1
--  EXEC AutoCompleteDropdowns 'AircraftType','AircraftTypeId','Description','',0,0,'0',1

CREATE PROCEDURE [dbo].[AutoCompleteDropdowns]    
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
	 IF(@TableName='Employee')    
	 BEGIN    
         IF(@Parameter4=1)    
         BEGIN      
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label    
               FROM dbo.Employee WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))    
               UNION     
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label FROM dbo.Employee  WITH(NOLOCK)
               WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) ORDER BY FirstName+' '+LastName        
         END    
		 ELSE    
         BEGIN    
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label    
               FROM dbo.Employee WITH(NOLOCK) WHERE  MasterCompanyId = @MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0  AND FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'    
               UNION     
               SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label  FROM dbo.Employee WITH(NOLOCK)
               WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,',')) 
         END        
     END    
     ELSE    
     BEGIN    
     IF(@Parameter4=1)    
     BEGIN 
			SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
										 SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
										         CAST ( '+ @Parameter2+  ' AS VARCHAR) AS Label, 
												 MasterCompanyId FROM dbo.'+@TableName+     
           ' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
            
            INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
		          SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
			             CAST(' + @Parameter2 + ' AS VARCHAR) AS Label,
						 MasterCompanyId FROM dbo.' + @TableName+     
           ' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR) !='''' AND '+@Parameter2+'  LIKE '''+ @Parameter3 +'%'''    
     END    
     ELSE    
     BEGIN  
			SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
	                         SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
							 CAST(' + @Parameter2 + ' AS VARCHAR) AS Label,
							 MasterCompanyId FROM  dbo.'+@TableName+     
			' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
             
			INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
		          SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,
				  CAST(' + @Parameter2 + ' AS VARCHAR) AS Label,
				  MasterCompanyId FROM dbo.'+@TableName+     
			' WITH(NOLOCK) WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''';    
     END    
     END 
  END
  ELSE
  BEGIN
  IF(@TableName='Employee')    
  BEGIN    
  IF(@Parameter4=1)    
  BEGIN      
		SELECT DISTINCT top 20 EmployeeId AS Value,FirstName+' '+LastName AS Label    
            FROM dbo.Employee WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))    
   UNION     
		SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label    
            FROM dbo.Employee  WITH(NOLOCK)    
		WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
  END    
  ELSE    
  BEGIN    
		SELECT DISTINCT top 20 EmployeeId AS Value,FirstName+' '+LastName AS Label    
            FROM dbo.Employee WITH(NOLOCK)  WHERE  MasterCompanyId = @MasterCompanyId AND IsActive=1 AND ISNULL(IsDeleted,0)=0  AND (FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%')    
   UNION     
		SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label    
            FROM dbo.Employee WITH(NOLOCK)     
			WHERE MasterCompanyId = @MasterCompanyId AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
  END
  END    
  ELSE    
  BEGIN    
  IF(@Parameter4=1)    
  BEGIN 
     SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
										 SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,
										         CAST ( '+ @Parameter2+  ' AS VARCHAR) AS Label, 
												 MasterCompanyId FROM  dbo.'+@TableName+     
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
            
        INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
		       SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,
			             CAST('+ @Parameter2 + ' AS VARCHAR) AS Label,
						 MasterCompanyId FROM  dbo.'+@TableName+     
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR) !='''' AND '+@Parameter2+'  LIKE '''+ @Parameter3 +'%'''    
   END    
   ELSE    
   BEGIN
     SET @Sql = N'INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
	                         SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,
							 CAST ( '+ @Parameter2+  ' AS VARCHAR) AS Label,
							 MasterCompanyId FROM  dbo.'+@TableName+     
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))    
             
          INSERT INTO #TempTable (Value, Label, MasterCompanyId) 
		          SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,
				  CAST('+ @Parameter2 + ' AS VARCHAR) AS Label,
				  MasterCompanyId FROM  dbo.'+@TableName+     
          ' WHERE MasterCompanyId =  '  + CAST (@MasterCompanyId AS nvarchar(50)) + '  AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''';    
    END    
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
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdowns'
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