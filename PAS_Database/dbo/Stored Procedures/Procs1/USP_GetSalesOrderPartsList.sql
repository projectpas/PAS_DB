/*************************************************************           
 ** File:   [USP_GetSalesOrderPartsList]           
 ** Author:   Hemant Saliya
 ** Description: 
 ** Purpose:         
 ** Date:   02/17/2022        
          
 ** PARAMETERS:           
 @MasterCompanyId BIGINT   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    03/22/2023   Hemant Saliya		Created
	2    10/17/2024   Vishal Suthar		Modified to make use of new SO tables
     
 EXECUTE USP_GetSalesOrderPartsList 254
**************************************************************/
CREATE PROCEDURE [dbo].[USP_GetSalesOrderPartsList]    
(    
@SalesOrderId INT
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    
		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN 
				SELECT DISTINCT SOP.ItemMasterId, IM.partnumber, SalesOrderPartId 
				FROM dbo.SalesOrderPartV1 SOP  WITH(NOLOCK) 
				JOIN dbo.ItemMaster IM WITH(NOLOCK)  ON SOP.ItemMasterId = IM.ItemMasterId
				WHERE SOP.SalesOrderId = @SalesOrderId
				GROUP BY SOP.ItemMasterId, SalesOrderPartId, IM.partnumber
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSalesOrderPartsList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END