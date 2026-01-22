/*************************************************************           
 ** File:   [USP_GetPOListNonstockByMasterItemId]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to Get POList Non stock By MasterItemId
 ** Purpose:         
 ** Date:   09-04-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    09-04-2025    Sahdev Saliya       Created  

**************************************************************/  
CREATE   PROCEDURE [dbo].[USP_GetPOListNonstockByMasterItemId]
@ItemMasterId BIGINT
AS
BEGIN
    SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY
    -- Selecting distinct purchase orders based on conditions
    SELECT DISTINCT
        po.PurchaseOrderId,
        po.PurchaseOrderNumber
    FROM
        [dbo].PurchaseOrder po WITH(NOLOCK)
    JOIN [dbo].PurchaseOrderPart pop WITH(NOLOCK) ON po.PurchaseOrderId = pop.PurchaseOrderId
    WHERE
        pop.ItemMasterId = @ItemMasterId
        AND po.IsDeleted = 0 
        AND pop.ItemTypeId = (SELECT ItemTypeId FROM [dbo].ItemType WITH(NOLOCK) WHERE [Name] = 'Non-Stock')
	END TRY    

	BEGIN CATCH      
		IF @@trancount > 0
			PRINT 'ROLLBACK'
            ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetPOListNonstockByMasterItemId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + ''
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