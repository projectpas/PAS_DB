
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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    15/12/2023  Rajesh Gami     Created
     
************************************************************************/

CREATE   PROCEDURE [dbo].[SP_SaveSOPartStatusByPartId]
@SalesOrderPartId bigint NULL= 0,
@StatusId int NULL= 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN 
		IF(@SalesOrderPartId > 0 AND @StatusId >0)
		BEGIN
			UPDATE dbo.SalesOrderPart set StatusId = @StatusId WHERE SalesOrderPartId = @SalesOrderPartId;
		END
	END	
	COMMIT  TRANSACTION
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
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