/***************************************************************  
 ** File:   [USP_GetExternalCustomerList]             
 ** Author:   Devendra Shekh  
 ** Description: This stored procedure is used to get customer list with external affiliation
 ** Purpose:           
 ** Date:   08/04/2024  [mm/dd/yyyy]
            
  ** Change History             
 **************************************************************             
 ** PR   Date				Author  				Change Description              
 ** --   --------			-------					--------------------------------            
    1    08/04/2024			Devendra Shekh			Created


	EXEC [USP_GetExternalCustomerList] '','', 1
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetExternalCustomerList]
@SearchText VARCHAR(50)= null,
@Idlist VARCHAR(max)='0',  
@MasterCompanyId int = NULL
AS
BEGIN	
	    SET NOCOUNT ON;
	    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED	
		BEGIN TRY

		DECLARE @RecordFrom int;		
		DECLARE @ExternalAffiliationId int;
		SET @ExternalAffiliationId = (SELECT CustomerAffiliationId FROM [dbo].[CustomerAffiliation] WITH(NOLOCK) where [Description] = 'External');

		IF OBJECT_ID('tempdb..#TempTable') IS NOT NULL
			DROP TABLE #TempTable

		CREATE TABLE #TempTable(      
		   [Value] BIGINT,      
		   [Label] VARCHAR(MAX),  
		   [MasterCompanyId] INT
		   )        
		--;WITH Result AS(
		INSERT INTO #TempTable ([Value], [Label], [MasterCompanyId])   
		SELECT DISTINCT
				C.CustomerId AS [Value],
				C.[Name] AS [Label],
				C.MasterCompanyId
				FROM dbo.Customer C WITH (NOLOCK)
				WHERE MasterCompanyId =  @MasterCompanyId AND CustomerAffiliationId = @ExternalAffiliationId AND CAST (CustomerId AS VARCHAR(MAX) ) IN (SELECT Item FROM DBO.SPLITSTRING('@Idlist',','))

		INSERT INTO #TempTable ([Value], [Label], [MasterCompanyId])   
		SELECT DISTINCT
				C.CustomerId AS [Value],
				C.[Name] AS [Label],
				C.MasterCompanyId
				FROM dbo.Customer C WITH (NOLOCK)
				WHERE MasterCompanyId = @MasterCompanyId AND CustomerAffiliationId = @ExternalAffiliationId AND IsActive=1 AND ISNULL(IsDeleted,0) = 0 AND CAST ([Name] AS VARCHAR(MAX)) !='' AND [Name] LIKE '%' + @SearchText +'%'
			--)
			SELECT * FROM #TempTable ORDER BY [Label]
	END TRY    
	BEGIN CATCH      
		DECLARE @ErrorLogID INT
			,@DatabaseName VARCHAR(100) = db_name()
			-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
			,@AdhocComments VARCHAR(150) = 'USP_GetExternalCustomerList'
			,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SearchText, '') AS varchar(100))
			   + '@Parameter2 = ''' + CAST(ISNULL(@Idlist, '') AS varchar(100))
			  + '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))  			                                           
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