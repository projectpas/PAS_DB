/*************************************************************           
 ** File:   [USP_GetFieldNameByModuleId_TrailBalance]           
 ** Author: Hemant Saliya
 ** Description: This stored procedure is used retrieve Partnumber and stockline userd
 ** Purpose:         
 ** Date:   06/20/2023 

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/20/2023   Hemant Saliya Created	
	2    08/13/2023   Hemant Saliya UPDATED for Report Name	
     
--EXEC [USP_GetFieldNameByModuleId_TrailBalance] 1
**************************************************************/
CREATE     PROCEDURE [dbo].[USP_GetFieldNameByModuleId_TrailBalance]
(
	@masterCompanyId VARCHAR(100) = NULL
)
AS
BEGIN 
	BEGIN TRY
		
			IF OBJECT_ID(N'tempdb..#TEMPFieldMaster') IS NOT NULL    
			BEGIN    
				DROP TABLE #TEMPFieldMaster
			END   
			
			DECLARE @FieldName VARCHAR(25);
			DECLARE @ModuleId INT;
			DECLARE @cols AS NVARCHAR(MAX); 
			DECLARE @query AS NVARCHAR(MAX);
			DECLARE @count INT;

			CREATE TABLE #TEMPFieldMaster(        
				ID BIGINT  IDENTITY(1,1),
				SequenceNo INT,
				FieldName nvarchar(100),
				HeaderName  nvarchar(100))
				
			SELECT @ModuleId = ModuleId FROM dbo.FieldsMaster WITH (NOLOCK) WHERE ModuleId = (SELECT TOP 1 ModuleId FROM dbo.Module where ModuleName = 'TrialBalance')

			INSERT INTO #TEMPFieldMaster(SequenceNo, FieldName,HeaderName)
			SELECT SequenceNo, CAST('level' + CAST(SequenceNo AS varchar(100)) AS varchar(100)) as leval, [Description] 
			FROM  dbo.ManagementStructureType WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId

			SELECT @count = COUNT(*) FROM #TEMPFieldMaster

			WHILE @count < 10
			BEGIN
				INSERT INTO #TEMPFieldMaster(SequenceNo, FieldName,HeaderName)
				SELECT @count + 1, CAST('level' + CAST((ISNULL(@count, 0) + 1) AS varchar(100)) AS varchar(100)), NULL

				SET @count = @count + 1
			END

			INSERT INTO #TEMPFieldMaster(SequenceNo, FieldName,HeaderName)
			SELECT FieldSortOrder, FieldName, HeaderName 
			FROM dbo.FieldsMaster WITH(NOLOCK) 
			WHERE ModuleId = @ModuleId and HeaderName != 'ms'

			SELECT @cols = STUFF((SELECT ',' + QUOTENAME(FieldName)   
			FROM #TEMPFieldMaster  
			  FOR XML PATH(''), TYPE).value('.', 'NVARCHAR(MAX)'), 1, 1, '')

			SET @query = 'select *
						  from
						  (
						    select HeaderName, FieldName
						    from #TEMPFieldMaster
						  ) d
						  pivot
						  (
						    max(HeaderName)
						  for FieldName in (' + @cols + ')
						  ) piv;'   
					
			--PRINT @query

			EXEC (@query)

			IF OBJECT_ID(N'tempdb..#TEMPFieldMaster') IS NOT NULL    
			BEGIN    
				DROP TABLE #TEMPFieldMaster
			END
		 
	
	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT  
	   ,@DatabaseName VARCHAR(100) = db_name()  
	   -----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
	   ,@AdhocComments VARCHAR(150) = 'USP_GetFieldNameByModuleId_TrailBalance'  
	   ,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  
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