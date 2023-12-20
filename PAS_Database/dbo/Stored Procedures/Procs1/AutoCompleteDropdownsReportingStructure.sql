/*************************************************************           
 ** File:   [AutoCompleteDropdownsAsset]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Asset List for Auto Complete Dropdown 
 ** Purpose:         
 ** Date:   10/06/2023        
          
 ** PARAMETERS: @UserType varchar(60)   
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    10/06/2023   Hemant Saliya Created
     
 EXEC [AutoCompleteDropdownsReportingStructure] '',1,20,'70,11',1
**************************************************************/
CREATE   PROCEDURE [dbo].[AutoCompleteDropdownsReportingStructure]
	@StartWith VARCHAR(50)= null,      
	@IsActive bit = true,      
	@Count VARCHAR(10) = '0',
	@Idlist VARCHAR(max)='0',    
	@MasterCompanyId int  
AS
BEGIN	
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY  

		DECLARE @Sql NVARCHAR(MAX);	
		IF(@Count = '0') 
		   BEGIN
		   set @Count='50';	
		END	

		IF(@IsActive = 1)
			BEGIN		
					SELECT DISTINCT TOP 50 
						RS.ReportingStructureId AS Value, 
						RS.ReportName AS Label,		
						RS.ReportingStructureId,
						RS.ReportName						
					FROM dbo.ReportingStructure RS WITH(NOLOCK)						
					WHERE RS.MasterCompanyId = @MasterCompanyId AND (RS.IsActive=1 AND ISNULL(RS.IsDeleted,0) = 0 AND (RS.ReportName LIKE @StartWith + '%'))
					
					UNION     
					
					SELECT DISTINCT  
						RS.ReportingStructureId AS Value, 
						RS.ReportName AS Label,		
						RS.ReportingStructureId,
						RS.ReportName						
					FROM dbo.ReportingStructure RS WITH(NOLOCK)	
					WHERE RS.MasterCompanyId = @MasterCompanyId AND RS.ReportingStructureId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
					ORDER BY Label				
			END
			ELSE
			BEGIN
					SELECT DISTINCT TOP 50 
						RS.ReportingStructureId AS Value, 
						RS.ReportName AS Label,		
						RS.ReportingStructureId,
						RS.ReportName						
					FROM dbo.ReportingStructure RS WITH(NOLOCK)						
					WHERE RS.MasterCompanyId = @MasterCompanyId AND ISNULL(RS.IsDeleted,0) = 0 AND (RS.ReportName LIKE @StartWith + '%')
					
					UNION     
					
					SELECT DISTINCT  
						RS.ReportingStructureId AS Value, 
						RS.ReportName AS Label,		
						RS.ReportingStructureId,
						RS.ReportName						
					FROM dbo.ReportingStructure RS WITH(NOLOCK)	
					WHERE RS.MasterCompanyId = @MasterCompanyId AND RS.ReportingStructureId in (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))    
					ORDER BY Label
			END	
	END TRY
	BEGIN CATCH	
			DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'AutoCompleteDropdownsReportingStructure'
			,@ProcedureParameters VARCHAR(3000) = '@StartWith = ''' + CAST(ISNULL(@StartWith, '') as varchar(100))
			   + '@IsActive = ''' + CAST(ISNULL(@IsActive, '') as varchar(100)) 
			   + '@Count = ''' + CAST(ISNULL(@Count, '') as varchar(100))  
			   + '@Idlist = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))			  
			   + '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') as varchar(100)) 
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