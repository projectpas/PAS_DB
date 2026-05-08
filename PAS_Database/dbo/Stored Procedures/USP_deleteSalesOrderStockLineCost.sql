/*************************************************************           
 ** File:   [USP_deleteSalesOrderStockLineCost]           
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used to Delete Part At Stockline Level
 ** Purpose:         
 ** Date: 08-05-2026    
 ** Jira Id: PN-15067  
          
 ** PARAMETERS: 

 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08-05-2026	  Bhargav Saliya	  Created 
************************************************************************/
CREATE     PROCEDURE [dbo].[USP_deleteSalesOrderStockLineCost]
	@SalesOrderId BIGINT = 0,
	@SalesOrderPartId BIGINT = 0,
	@MasterCompanyId BIGINT = 0
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
		IF EXISTS(SELECT * FROM dbo.[SalesOrderStocklineCost] WITH(NOLOCK) WHERE SalesOrderId = @SalesOrderId and SalesOrderPartId = @SalesOrderPartId and MasterCompanyId = @MasterCompanyId)
		BEGIN
			DELETE FROM dbo.[SalesOrderStocklineCost] WHERE SalesOrderId = @SalesOrderId and SalesOrderPartId = @SalesOrderPartId and MasterCompanyId = @MasterCompanyId
		END
		----------------------------------------
		IF EXISTS(SELECT * FROM dbo.[SalesOrderStocklineV1] WITH(NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId and MasterCompanyId = @MasterCompanyId)
		BEGIN
			DELETE FROM dbo.[SalesOrderStocklineV1] where SalesOrderPartId = @SalesOrderPartId and MasterCompanyId = @MasterCompanyId
		END
	END TRY
	BEGIN CATCH
	DECLARE @ErrorLogID INT
	,@DatabaseName VARCHAR(100) = db_name()
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
	,@AdhocComments VARCHAR(150) = 'USP_deleteSalesOrderStockLineCost'
	, @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderId, '') as Varchar(100)) + 
											  '@Parameter2 = '''+ CAST(ISNULL(@SalesOrderPartId, '') as Varchar(100))		
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