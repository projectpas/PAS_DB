
CREATE   PROCEDURE [dbo].[USP_FieldsMaster_GetByModuleId]
@ModuleId bigint,
@MasterCompanyId int
AS
BEGIN
SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
	BEGIN TRY

	CREATE TABLE #TEMPFieldMaster(      
	ID BIGINT  IDENTITY(1,1),      
	FieldName nvarchar(100),  
	HeaderName  nvarchar(100),
	FieldGridWidth nvarchar(10),
	FieldPDFWidth decimal(10,2),
	FieldExcelWidth decimal(10,2),
	FieldSortOrder INT,
	IsNumString BIT,
	IsRightAlign BIT)
    
	DECLARE  @mSSEQ AS INT 
	SELECT @mSSEQ = FieldSortOrder FROM dbo.FieldsMaster WITH (NOLOCK) WHERE ModuleId=@ModuleId AND FieldName = 'ms'

	INSERT INTO #TEMPFieldMaster  
	
	SELECT FieldName,HeaderName,FieldGridWidth,FieldPDFWidth,FieldExcelWidth,FieldSortOrder,ISNULL(IsNumString,0),ISNULL(IsRightAlign,0)
	FROM dbo.FieldsMaster WITH (NOLOCK) WHERE ModuleId=@ModuleId AND FieldName != 'ms'
	ORDER BY FieldSortOrder
	DECLARE @PDFpre decimal(10,2)

	SELECT @PDFpre=sum(isnull(FieldPDFWidth,0)) FROM #TEMPFieldMaster
	SET @PDFpre=100-@PDFpre


	DECLARE @inttotallevel int=0;
	SELECT @inttotallevel=count(MasterCompanyId) FROM ManagementStructureType WHERE MasterCompanyId=@MasterCompanyId

	DECLARE @HeaderName  NVARCHAR(100)=''
	DECLARE @SequenceNo INT
	DECLARE @intlevel INT=0

	IF @mSSEQ IS NOT NULL
	BEGIN
		DECLARE feildcursor CURSOR FOR 
		SELECT [Description] HeaderName,SequenceNo FROM ManagementStructureType WHERE MasterCompanyId=@MasterCompanyId ORDER BY SequenceNo
		OPEN feildcursor  
			FETCH NEXT FROM feildcursor INTO @HeaderName,@SequenceNo
				WHILE @@FETCH_STATUS = 0  
				BEGIN  
					SET @intlevel=@intlevel+1
					INSERT INTO #TEMPFieldMaster select 'level'+convert(varchar,@intlevel),@HeaderName,'200px',convert(decimal(10,2),(@PDFpre/@inttotallevel)),50,@mSSEQ,0,0
			FETCH NEXT FROM feildcursor INTO @HeaderName,@SequenceNo
				END 

				CLOSE feildcursor  
				DEALLOCATE feildcursor 
	END

	SELECT * FROM #TEMPFieldMaster ORDER BY FieldSortOrder,ID

	DECLARE @Sql NVARCHAR(MAX)=''
	CREATE TABLE #TempTable(Value BIGINT,Label VARCHAR(MAX),MasterCompanyId INT,AutoId BIGINT)     
	DECLARE @AutoId BIGINT
	DECLARE @TableName NVARCHAR(100)
	DECLARE @IDName NVARCHAR(50)
	DECLARE @ValueName NVARCHAR(50)
	DECLARE @ApplyFilter NVARCHAR(200)
	DECLARE @FieldType NVARCHAR(100)
	DECLARE tablefeildcursor CURSOR FOR 
			SELECT AutoId,TableName, IDName, ValueName,ISNULL(ApplyFilter,''),FieldType FROM dbo.GlobalFilter WHERE ModuleId=@ModuleId and isnull(TableName,'')!='' and IsActive=1 ORDER BY Sequnse ASC
				OPEN tablefeildcursor  
				FETCH NEXT FROM tablefeildcursor INTO @AutoId,@TableName,@IDName,@ValueName,@ApplyFilter,@FieldType
						WHILE @@FETCH_STATUS = 0  
							BEGIN  
							if(@FieldType='autoddl')
								begin
								
								SET @Sql = N'INSERT INTO #TempTable (Value, Label,MasterCompanyId,AutoId)   
								   SELECT DISTINCT top(20) CAST ( '+@IDName+' AS BIGINT) As Value,  
										   CAST ( '+ @ValueName+  ' AS VARCHAR) AS Label,MasterCompanyId, '+convert(varchar,@AutoId)+' FROM dbo.'+@TableName+       
								   ' WITH(NOLOCK)  where MasterCompanyId=0 or MasterCompanyId='+convert(varchar,@MasterCompanyId)+ ' '+@ApplyFilter+' order by Label'
								   EXEC sp_executesql @Sql; 
								end
								else
								begin

								SET @Sql = N'INSERT INTO #TempTable (Value, Label,MasterCompanyId,AutoId)   
								   SELECT DISTINCT  CAST ( '+@IDName+' AS BIGINT) As Value,  
										   CAST ( '+ @ValueName+  ' AS VARCHAR) AS Label,MasterCompanyId, '+convert(varchar,@AutoId)+' FROM dbo.'+@TableName+       
								   ' WITH(NOLOCK)  where MasterCompanyId=0 or MasterCompanyId='+convert(varchar,@MasterCompanyId)+ ' '+@ApplyFilter+' order by Label'
								   EXEC sp_executesql @Sql; 
								   end
							  FETCH NEXT FROM tablefeildcursor INTO @AutoId,@TableName,@IDName,@ValueName,@ApplyFilter,@FieldType
							END 

			CLOSE tablefeildcursor  
			DEALLOCATE tablefeildcursor 

			SELECT AutoId,[ModuleId], [LabelName], [FieldType], [Sequnse], [TableName], [IDName], [ValueName], [IsActive],IsRequired
			,CASE WHEN isnull(TableName,'')!='' then 
			(SELECT TT.Value,TT.Label FROM #TempTable TT WHERE TT.AutoId=GF.AutoId FOR JSON PATH )  ELSE '' END 
			AS FilterListValue
			FROM dbo.GlobalFilter GF
			WHERE ModuleId=@ModuleId  and IsActive=1 ORDER BY GF.Sequnse ASC
		
		SELECT ReportTitle,SPname,BredCum,case when @mSSEQ IS NULL THEN 1 ELSE 0 END 'disableMs' FROM  ReportMaster WHERE ModuleId=@ModuleId
	

	END TRY    
	BEGIN CATCH
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'UPS_FieldsMaster_GetByModuleId'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ModuleId, '') AS varchar(100))
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