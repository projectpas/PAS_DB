/*************************************************************           
 ** File:   [usp_ROListByMasterItemId]           
 ** Author:   Sahdev Saliya
 ** Description: This stored procedure is used to RO List By MasterItemId List
 ** Purpose:         
 ** Date:   05-05-2025       
          
 ** RETURN VALUE:           
  
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** S NO   Date            Author          Change Description              
 ** --   --------         -------          --------------------------------            
    1    05-05-2025    Sahdev Saliya       Created  
	2    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

**************************************************************/  
CREATE   PROCEDURE dbo.[usp_ROListByMasterItemId]
    @ItemMasterId BIGINT
AS
BEGIN
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON;

        BEGIN TRY

				SELECT DISTINCT
				RO.RepairOrderId,
				RO.RepairOrderNumber
				FROM [dbo].RepairOrder RO WITH(NOLOCK)
				INNER JOIN [dbo].RepairOrderPart ROP WITH(NOLOCK) ON RO.RepairOrderId = ROP.RepairOrderId
				LEFT JOIN [dbo].ItemMaster ITM WITH(NOLOCK) ON ROP.ItemMasterId = ITM.ItemMasterId AND ITM.ItemMasterId = @ItemMasterId
				 AND ISNULL(ITM.IsNonStock,0) = 0 LEFT JOIN [dbo].AssetInventory ASI WITH(NOLOCK) ON ROP.ItemMasterId = ASI.AssetRecordId AND ASI.AssetRecordId = @ItemMasterId
				WHERE RO.IsDeleted = 0 
        END TRY    

     BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'usp_ROListByMasterItemId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)) 
			 
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
	 END CATCH
END