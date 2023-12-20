/*************************************************************             
** File:   [AutoCompleteDropdownsBasedoncolumn]            
** Author:   Satish Gohil
** Description: This procedre is used to display record using table and column
** Purpose:           
** Date:   21/07/2023
**************************************************************             
** Change History             
**************************************************************             
** PR   Date         Author			Change Description              
** --   --------     -------		--------------------------------            
	1   08/08/2023   Satish Gohil	Modify(Formetted and fetch all record while pass count = 0)
    
**************************************************************/

CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsBasedoncolumn]
(
	@TableName VARCHAR(50)= null,      
	@Parameter1 VARCHAR(50) = null,      
	@Parameter2 VARCHAR(100)= null,      
	@Parameter3 VARCHAR(50)= null,      
	@Parameter4 bit = true,
	@Parameter5 VARCHAR(50)= null,  
	@Parameter6 VARCHAR(50) = null,  
	@Count VARCHAR(10) = '0',      
	@Idlist VARCHAR(max) = '0',      
	@MasterCompanyID  int      
)
AS      
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY
		DECLARE @Sql NVARCHAR(MAX); 
		CREATE TABLE #TempTable(      
		   Value BIGINT,      
		   Label VARCHAR(MAX)
		)    

		IF(@TableName='Employee')      
		BEGIN
			IF(@Parameter4=1) 
			BEGIN
				SELECT DISTINCT top 20 EmployeeId AS Value,FirstName+' '+LastName AS Label      
				FROM dbo.Employee WITH(NOLOCK) WHERE MasterCompanyID = @MasterCompanyID AND (IsActive=1 AND ISNULL(IsDeleted,0)=0 AND (FirstName LIKE @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'))      
				UNION  
				SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label      
				FROM dbo.Employee  WITH(NOLOCK)     
				WHERE MasterCompanyID = @MasterCompanyID AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))      
				ORDER BY Label  
			END
			ELSE
			BEGIN
				SELECT DISTINCT top 20 EmployeeId AS Value,FirstName+' '+LastName AS Label      
				FROM dbo.Employee WITH(NOLOCK) WHERE MasterCompanyID = @MasterCompanyID AND IsActive=1 AND ISNULL(IsDeleted,0)=0  AND FirstName LIKE '%' + @Parameter3 + '%' OR LastName  LIKE '%' + @Parameter3 + '%'      
				UNION       
				SELECT DISTINCT  EmployeeId AS Value,FirstName+' '+LastName AS Label      
					FROM dbo.Employee  WITH(NOLOCK)       
				WHERE MasterCompanyID = @MasterCompanyID AND EmployeeId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))      
				ORDER BY Label
			END
		END
		ELSE
		BEGIN
			IF(@Parameter4=1)
			BEGIN
				IF (@Parameter5 IS NOT NULL  AND @Parameter5 !='' AND  @Parameter6 IS NOT NULL  AND @Parameter6 !='')
				BEGIN
					IF(@Count = '0')
					BEGIN
						SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
						' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
              
						INSERT INTO #TempTable (Value, Label) SELECT DISTINCT CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM dbo.' + @TableName+       
						' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(100)) !='''' AND '+@Parameter2+'  LIKE '''+ @Parameter3 +'%''  AND CAST ( '+ @Parameter5 +' AS VARCHAR) = '+@Parameter6+'       
						ORDER BY Label'  
					END
					ELSE
					BEGIN
						SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
						' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
              
						INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM dbo.' + @TableName+       
						' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(100)) !='''' AND '+@Parameter2+'  LIKE '''+ @Parameter3 +'%''  AND CAST ( '+ @Parameter5 +' AS VARCHAR) = '+@Parameter6+'       
						ORDER BY Label' 
					END
				END
				ELSE
				BEGIN
					IF(@Count = '0')
					BEGIN
						SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM dbo.'+@TableName+       
						  ' WHERE CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
              
							INSERT INTO #TempTable (Value, Label) SELECT DISTINCT CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
							  ' WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(100)) !='''' AND '+@Parameter2+'  LIKE '''+ @Parameter3 +'%''         
							  ORDER BY Label' 
					END
					ELSE
					BEGIN
						SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT  CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM dbo.'+@TableName+       
						  ' WHERE CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
              
							INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
							  ' WHERE IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(100)) !='''' AND '+@Parameter2+'  LIKE '''+ @Parameter3 +'%''         
							  ORDER BY Label'
					END
				END
			END
			
			ELSE 
			BEGIN
				IF(@Count = '0')
				BEGIN
					SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
					  ' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
               
					  INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
					  ' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(100)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''  ORDER BY Label';      
				END
				ELSE
				BEGIN
					SET @Sql = N'INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
					  ' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND CAST ( '+@Parameter1+' AS VARCHAR ) IN (SELECT Item FROM DBO.SPLITSTRING('''+ @Idlist +''','',''))      
               
					  INSERT INTO #TempTable (Value, Label) SELECT DISTINCT TOP ' +@Count+ ' CAST ( '+@Parameter1+' AS BIGINT) As Value,CAST ( '+ @Parameter2+  ' AS VARCHAR(100)) AS Label FROM  dbo.'+@TableName+       
					  ' WHERE MasterCompanyId = ' + CAST ( @MasterCompanyId AS nvarchar(50) ) + ' AND IsActive=1 AND ISNULL(IsDeleted,0)=0 AND CAST ( '+@Parameter2+' AS VARCHAR(100)) !='''' AND '+@Parameter2+'  LIKE ''%'+ @Parameter3 +'%''  ORDER BY Label';      
				END
			END
		END

		PRINT @Sql      
		EXEC sp_executesql @Sql;      
		SELECT DISTINCT * FROM #TempTable      
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
		,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsBasedoncolumn'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@TableName, '') as varchar(100))
			+ '@Parameter2 = ''' + CAST(ISNULL(@Parameter1, '') as varchar(100)) 
			+ '@Parameter3 = ''' + CAST(ISNULL(@Parameter2, '') as varchar(100))  
			+ '@Parameter4 = ''' + CAST(ISNULL(@Parameter3, '') as varchar(100))  
			+ '@Parameter5 = ''' + CAST(ISNULL(@Parameter4, '') as varchar(100))  
			+ '@Parameter6 = ''' + CAST(ISNULL(@Parameter5, '') as varchar(100))  
			+ '@Parameter7 = ''' + CAST(ISNULL(@Parameter6, '') as varchar(100)) 
			+ '@Parameter8 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			+ '@Parameter9 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100)) 
			+ '@Parameter10 = ''' + CAST(ISNULL(@MasterCompanyID, '') as varchar(100))  			                                           
		,@ApplicationName VARCHAR(100) = 'PAS'

	-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
	EXEC spLogException @DatabaseName = @DatabaseName
		,@AdhocComments = @AdhocComments
		,@ProcedureParameters = @ProcedureParameters
		,@ApplicationName = @ApplicationName
		,@ErrorLogID = @ErrorLogID OUTPUT;

	RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)

	RETURN (1);	
	END CATCH
END