﻿/*************************************************************             
 ** File:   [GetSalesOrderPartsViewById]             
 ** Author:  AMIT GHEDIYA 
 ** Description: This stored procedure is used GetSalesOrderPartsViewById 
 ** Purpose:           
 ** Date:  03/06/2024        
            
 ** PARAMETERS: @SalesOrderId bigint  
           
 ** RETURN VALUE:             
 **************************************************************             
 ** Change History             
 **************************************************************             
 ** PR   Date			 Author			Change Description              
 ** --   --------		-------			--------------------------------            
    1    03/06/2024		AMIT GHEDIYA	 Created  

-- exec GetSalesOrderPartsViewById 891   
************************************************************************/   
CREATE     PROCEDURE [dbo].[GetSalesOrderPartsViewById]    
	@SalesOrderId BIGINT    
AS    
BEGIN    
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED    
 SET NOCOUNT ON;    
 BEGIN TRY        
   BEGIN       
		SELECT 
			 ROW_NUMBER() OVER (
				ORDER BY part.SalesOrderId
			 ) row_num, 
			part.PONumber,
			itemMaster.PartNumber,
			itemMaster.PartDescription,
			ISNULL(qs.StockLineNumber, '') AS StockLineNumber,
			qs.SerialNumber AS SerialNumber,
			part.Qty,
			ISNULL(cp.Description, '') AS Condition
		FROM  [dbo].[SalesOrderPart] part WITH(NOLOCK)
		LEFT JOIN [dbo].[StockLine] qs WITH(NOLOCK) ON part.StockLineId = qs.StockLineId
		LEFT JOIN [dbo].[ItemMaster] itemMaster WITH(NOLOCK) ON part.ItemMasterId = itemMaster.ItemMasterId
		LEFT JOIN [dbo].[ItemMasterExportInfo] imx WITH(NOLOCK) ON itemMaster.ItemMasterId = imx.ItemMasterId
		LEFT JOIN [dbo].[Manufacturer] mf WITH(NOLOCK) ON itemMaster.ManufacturerId = mf.ManufacturerId
		LEFT JOIN [dbo].[Condition] cp WITH(NOLOCK) ON part.ConditionId = cp.ConditionId
		WHERE part.SalesOrderId = @SalesOrderId  AND part.IsDeleted = 0
		ORDER BY part.ItemNo;
  END    
  END TRY    
 BEGIN CATCH          
  IF @@trancount > 0    
   PRINT 'ROLLBACK'    
   ROLLBACK TRAN;    
   DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
            , @AdhocComments     VARCHAR(150)    = 'GetSalesOrderPartsViewById'     
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SalesOrderId, '') + ''    
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