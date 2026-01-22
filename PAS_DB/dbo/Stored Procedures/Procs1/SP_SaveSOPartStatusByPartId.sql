/*************************************************************           
 ** File:   [SP_SaveSOPartStatusByPartId]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to save part status by part id
 ** Purpose:         
 ** Date:  15/12/2023   
          
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    15/12/2023  Rajesh Gami		Created
    2    19/12/2023  Rajesh Gami		changes by rajesh
	3    11/04/2024	 Vishal Suthar		Modified to make use of new SO Part tables
	4    11/04/2024	 Rajesh Gami		Modified : Implemented statusID logic in the SalesOrderStocklineV1
	5    14/07/2025	 Rajesh Gami		Call the SP for update SO Header status
     
************************************************************************/

CREATE    PROCEDURE [dbo].[SP_SaveSOPartStatusByPartId]
@SalesOrderPartId bigint NULL= 0,
@StatusId int NULL= 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	
		IF(@SalesOrderPartId > 0 AND @StatusId >0)
		BEGIN
			DECLARE @SOID BIGINT = (SELECT TOP 1 SalesOrderId FROM DBO.SalesOrderPartV1 WITH(NOLOCK) WHERE SalesOrderPartId = @SalesOrderPartId);
			DECLARE @ClosedStatusId INT =(SELECT TOP 1 id FROM Dbo.MasterSalesOrderStatus  WITH(NOLOCK) WHERE Description = 'Closed')
			DECLARE @IsSOClosed BIT = (CASE WHEN ISNULL((SELECT TOP 1 SalesOrderId FROM dbo.SalesOrder  WITH(NOLOCK) WHERE SalesOrderId = @SOID AND StatusId = @ClosedStatusId),0) > 0 THEN 1 ELSE 0 END)
			IF(@IsSOClosed = 1)
			BEGIN
				DECLARE @partCloseStatusId int = (SELECT SOPartStatusId FROM DBO.SOPartStatus  WITH(NOLOCK) WHERE Description = 'Closed')
				UPDATE dbo.SalesOrderPartV1 set StatusId = @partCloseStatusId WHERE SalesOrderId = @SOID;
				UPDATE dbo.SalesOrderStocklineV1 set StatusId = @partCloseStatusId WHERE SalesOrderPartId = @SalesOrderPartId;
			END
			ELSE
			BEGIN
				UPDATE dbo.SalesOrderPartV1 set StatusId = @StatusId WHERE SalesOrderPartId = @SalesOrderPartId;
				UPDATE dbo.SalesOrderStocklineV1 set StatusId = @StatusId WHERE SalesOrderPartId = @SalesOrderPartId;
				EXEC [dbo].[SP_UpdateSOHeaderStatusBySOId] @SOID
			END
		END

	END TRY 
	BEGIN CATCH      
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'SP_SaveSOPartStatusByPartId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ CAST(ISNULL(@SalesOrderPartId, '') AS varchar(100))
													+ '@Parameter2 = ''' + CAST(ISNULL(@StatusId, '') AS varchar(100))  
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END