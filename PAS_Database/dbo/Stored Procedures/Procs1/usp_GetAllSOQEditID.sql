
CREATE Procedure [dbo].[usp_GetAllSOQEditID]
 @soqID  bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION

		IF OBJECT_ID(N'tempdb..#SOQEditList') IS NOT NULL
		BEGIN
		DROP TABLE #SOQEditList 
		END
		CREATE TABLE #SOQEditList 
		(
		 ID bigint NOT NULL IDENTITY,
		 [Value] bigint null,
		 Label varchar(100) null
		)

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT EmployeeId, 'EMPLOYEE' FROM dbo.SalesOrderQuote WITH(NOLOCK) Where SalesOrderQuoteId = @soqID

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT QuoteTypeId, 'QUOTETYPE' FROM dbo.SalesOrderQuote WITH(NOLOCK) Where SalesOrderQuoteId = @soqID

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT CustomerId, 'CUSTOMERID' FROM dbo.SalesOrderQuote WITH(NOLOCK) Where SalesOrderQuoteId = @soqID

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT ISNULL( CustomerContactId, 0), 'CUSTOMERCONTACT' FROM dbo.SalesOrderQuote WITH(NOLOCK) Where SalesOrderQuoteId = @soqID

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT ISNULL( SalesPersonId, 0) , 'SALESPERSON' FROM dbo.SalesOrderQuote WITH(NOLOCK) Where SalesOrderQuoteId = @soqID

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT ISNULL( CustomerSeviceRepId, 0) , 'CUSTOMERSERVICEREP' FROM dbo.SalesOrderQuote WITH(NOLOCK) Where SalesOrderQuoteId = @soqID

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT ISNULL( ItemMasterId, 0) , 'ITEMMASTER' FROM dbo.SalesOrderQuotePart WITH(NOLOCK) Where SalesOrderQuoteId = @soqID

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT  ISNULL( StockLineId, 0) , 'STOCKLINEID' FROM dbo.SalesOrderQuotePart WITH(NOLOCK) Where SalesOrderQuoteId = @soqID


		INSERT INTO #SOQEditList ([Value],Label)
		SELECT UserType, 'SHIP_TYPE' FROM dbo.SalesOrderQuoteAddress WITH(NOLOCK) Where SalesOrderQuoteId = @soqID AND IsShippingAdd = 1

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT UserType, 'BILL_TYPE' FROM dbo.SalesOrderQuoteAddress WITH(NOLOCK) Where SalesOrderQuoteId = @soqID AND IsShippingAdd = 0

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT UserId, 'BILL_USERID' FROM dbo.SalesOrderQuoteAddress WITH(NOLOCK) Where SalesOrderQuoteId = @soqID AND IsShippingAdd = 0

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT UserId, 'SHIP_USERID' FROM dbo.SalesOrderQuoteAddress WITH(NOLOCK) Where SalesOrderQuoteId = @soqID AND IsShippingAdd = 1

		INSERT INTO #SOQEditList ([Value],Label)
		SELECT ISNULL(MS.LegalEntityId,0), 'MSCOMPANYID' from dbo.SalesOrderQuote SOQ WITH(NOLOCK)
		INNER JOIN dbo.ManagementStructure MS WITH(NOLOCK) ON SOQ.ManagementStructureId = MS.ManagementStructureId
		WHERE SalesOrderQuoteId = @soqID 

		SELECT * FROM #SOQEditList
	COMMIT  TRANSACTION

	END TRY    
	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'usp_GetAllSOQEditID' 
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@soqID, '') + ''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID                    = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH	
END