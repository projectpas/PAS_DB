/*************************************************************           
 ** File:   [USP_deleteSalesOrderQuoteStocklinePart]           
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used to Delete Part At Stockline Level
 ** Purpose:         
 ** Date: 25-06-2025    
 ** Jira Id: PN-16085   
          
 ** PARAMETERS: 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    22-04-2026	  Bhargav Saliya	  Created 
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_deleteSalesOrderQuoteStocklinePart]
	@SalesOrderQuoteId BIGINT = 0,
	@SalesOrderQuotePartId BIGINT = 0,
	@MasterCompanyId BIGINT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		IF EXISTS(SELECT * FROM dbo.SalesOrderQuoteStocklineCost WITH(NOLOCK) WHERE SalesOrderQuoteId = @SalesOrderQuoteId and SalesOrderQuotePartId = @SalesOrderQuotePartId and MasterCompanyId = @MasterCompanyId)
		BEGIN
			DELETE FROM dbo.SalesOrderQuoteStocklineCost where SalesOrderQuoteId = @SalesOrderQuoteId and SalesOrderQuotePartId = @SalesOrderQuotePartId and MasterCompanyId = @MasterCompanyId
		END
		----------------------------------------
		IF EXISTS(SELECT * FROM dbo.SalesOrderQuoteStocklineV1 WITH(NOLOCK) WHERE SalesOrderQuotePartId = @SalesOrderQuotePartId and MasterCompanyId = @MasterCompanyId)
		BEGIN
			DELETE FROM dbo.SalesOrderQuoteStocklineV1 where SalesOrderQuotePartId = @SalesOrderQuotePartId and MasterCompanyId = @MasterCompanyId
		END
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_SOQResetApprovalProcess'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderQuoteId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SalesOrderQuotePartId, '') as Varchar(100))		
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