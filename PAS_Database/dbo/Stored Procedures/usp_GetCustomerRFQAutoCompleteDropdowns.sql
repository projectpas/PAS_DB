/*************************************************************             
** File:   [usp_GetCustomerRFQAutoCompleteDropdowns]            
** Author:   Devendra Shekh
** Description: This procedre is used to get the Customer RFQ List Result For Drop Down
** Purpose:           
** Date:   4-Dec-2025
**************************************************************             
** Change History             
**************************************************************             
** PR   Date			Author					Change Description              
** --   --------		-------				--------------------------------            
	1   4-Dec-2025		Devendra Shekh			Created
    
EXEC [dbo].[usp_GetCustomerRFQAutoCompleteDropdowns] '', '', '', 1, 'A1001', ''
exec dbo.usp_GetCustomerRFQAutoCompleteDropdowns @SearchText=default,@Count=N'20',@Idlist=default,@MasterCompanyId=1,@PartNumber=N'A100',@Condition=N'NE'
**************************************************************/
CREATE   PROCEDURE [dbo].[usp_GetCustomerRFQAutoCompleteDropdowns]
(
	@SearchText VARCHAR(50) = '',      
	@Count VARCHAR(10) = '0',      
	@Idlist VARCHAR(MAX) = '0',      
	@MasterCompanyId  int, 
	@PartNumber VARCHAR(250) = '',
	@Condition VARCHAR(250) = ''
)
AS      
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON  
	BEGIN TRY

		DECLARE @Sql NVARCHAR(MAX);
		SET @Count = CASE WHEN ISNULL(@Count, '0') = 0 THEN '20' ELSE @Count END;

		CREATE TABLE #TempTable (
		   [Value] BIGINT,
		   [Label] VARCHAR(MAX),
		   [ReferenceNumber] NVARCHAR(400),
		)

		SET @Sql =
		N'	INSERT INTO #TempTable ([Value], [Label], [ReferenceNumber])
			SELECT DISTINCT TOP ' + @Count+ ' CRF.CustomerRfqId AS Value, CONCAT(RfqId, '' - '', BuyerCompanyName) AS Label, RfqId
			FROM [dbo].[CustomerRfq] CRF WITH(NOLOCK)
			LEFT JOIN [dbo].[CustomerRfqPartMapping] RFQM WITH(NOLOCK) ON CRF.CustomerRfqId = RFQM.CustomerRfqId
			WHERE CRF.MasterCompanyID = ' + CAST(@MasterCompanyID AS NVARCHAR(50)) + ' AND CRF.IsActive = 1 AND ISNULL(CRF.IsDeleted,0) = 0 AND RfqId LIKE ''%'+ @SearchText +'%''
			AND ((CRF.LinePartNumber LIKE ''%'+ @PartNumber +'%'') OR (RFQM.PartNumber LIKE ''%'+ @PartNumber +'%''))
		'

		PRINT @Sql
		EXEC sp_executesql @Sql;
		
		INSERT INTO #TempTable ([Value], [Label], [ReferenceNumber])
		SELECT DISTINCT CustomerRfqId AS Value, CONCAT(RfqId, ' - ', BuyerCompanyName) AS Label, RfqId
		FROM [dbo].[CustomerRfq] WITH(NOLOCK)
		WHERE MasterCompanyID = @MasterCompanyID AND CustomerRfqId IN (SELECT Item FROM DBO.SPLITSTRING(@Idlist,','))
		ORDER BY Label
		
		SELECT DISTINCT [Value], [Label], [ReferenceNumber] FROM #TempTable;
		DROP Table #TempTable;

	END TRY
	BEGIN CATCH
		DECLARE @ErrorLogID INT
		,@DatabaseName VARCHAR(100) = db_name() 
		-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
		,@AdhocComments VARCHAR(150) = 'usp_GetCustomerRFQAutoCompleteDropdowns'
		,@ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@SearchText, '') as varchar(100))
			+ '@Parameter2 = ''' + CAST(ISNULL(@Count, '') as varchar(100)) 
			+ '@Parameter3 = ''' + CAST(ISNULL(@Idlist, '') as varchar(100))  
			+ '@Parameter4 = ''' + CAST(ISNULL(@MasterCompanyID, '') as varchar(100))  
			+ '@Parameter5 = ''' + CAST(ISNULL(@PartNumber, '') as varchar(100))  
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