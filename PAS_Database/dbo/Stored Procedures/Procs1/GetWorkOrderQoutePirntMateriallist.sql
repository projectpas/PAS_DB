/*************************************************************             
 ** File:   [GetWorkOrderPrintPdfData]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used Work order Print  Details      
 ** Purpose:           
 ** Date:   12/30/2020          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    06/02/2020    Subhash Saliya   Created  
    2    06/17/2025    Hemant  Saliya   Check For Is deleted Condition  
    3    09/04/2026    Ayushi Patel	    PN-15909 Update (Added UOM Changes)   
--EXEC [GetWorkOrderQoutePirntMateriallist] 10338,10476,8307
**************************************************************/  
--SELECT  * FROM WorkOrderQuoteMaterial mt WITH(NOLOCK)   
CREATE     PROCEDURE [dbo].[GetWorkOrderQoutePirntMateriallist]  
@WorkflowWorkOrderId bigint,  
@workOrderPartNoId bigint,  
@workOrderQuoteDetailsId bigint  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    SELECT  
        --mt.Quantity,  
        ISNULL([dbo].[fn_ConvertUOM](ISNULL(mt.Quantity,0),ISNULL(imt.[StockUnitOfMeasure],0),ISNULL(imt.[ConsumeUnitOfMeasure],0),0,ISNULL(imt.[MasterCompanyId],0)),0) AS Quantity,
        mt.UomName,  
        mt.PartNumber as partnumber,  
        mt.ConditionType AS Condition,  
        mt.PartDescription as PartDescription,  
        --(mt.BillingAmount / isnull(mt.Quantity,0)) as UnitCost, 
        (
            CASE 
                WHEN ISNULL(mt.Quantity,0) = 0
                THEN 0
                ELSE
                    mt.BillingAmount /
                    ISNULL([dbo].[fn_ConvertUOM](
                        ISNULL(mt.Quantity,0),
                        ISNULL(imt.[StockUnitOfMeasure],0),
                        ISNULL(imt.[ConsumeUnitOfMeasure],0),
                        0,
                        ISNULL(imt.[MasterCompanyId],0)
                    ),0)
            END
        ) AS UnitCost,
	    --(mt.Quantity * (mt.BillingAmount / isnull(mt.Quantity,0))) as extCost  
        (
            ISNULL([dbo].[fn_ConvertUOM](
                ISNULL(mt.Quantity,0),
                ISNULL(imt.[StockUnitOfMeasure],0),
                ISNULL(imt.[ConsumeUnitOfMeasure],0),
                0,
                ISNULL(imt.[MasterCompanyId],0)
            ),0)
            *
            (
                CASE 
                    WHEN ISNULL(mt.Quantity,0) = 0
                    THEN 0
                    ELSE
                        mt.BillingAmount /
                        ISNULL([dbo].[fn_ConvertUOM](
                            ISNULL(mt.Quantity,0),
                            ISNULL(imt.[StockUnitOfMeasure],0),
                            ISNULL(imt.[ConsumeUnitOfMeasure],0),
                            0,
                            ISNULL(imt.[MasterCompanyId],0)
                        ),0)
                END
            )
        ) AS extCost
    FROM WorkOrderQuoteMaterial mt WITH(NOLOCK)    
        INNER JOIN WorkOrderQuoteDetails wop WITH(NOLOCK) on wop.WorkOrderQuoteDetailsId = mt.WorkOrderQuoteDetailsId   
        LEFT JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = mt.ItemMasterId  
    WHERE wop.WorkflowWorkOrderId = @WorkflowWorkOrderId AND wop.WOPartNoId = @workOrderPartNoId  AND ISNULL(mt.IsDeleted, 0) = 0 AND ISNULL(mt.IsActive, 0) = 1
    --WHERE wop.WorkOrderQuoteDetailsId = @workOrderQuoteDetailsId  

	UNION ALL
	SELECT  --wom.Quantity, 
    ISNULL([dbo].[fn_ConvertUOM](ISNULL(wom.Quantity,0),ISNULL(im.[StockUnitOfMeasure],0),ISNULL(im.[ConsumeUnitOfMeasure],0),0,ISNULL(im.[MasterCompanyId],0)),0) AS Quantity,
        '-' as UomName,  
        wom.KitNumber as partnumber,  
        '-' AS Condition,  
        KIM.KitDescription as PartDescription,  
        --(wom.BillingAmount / isnull(wom.Quantity,0)) as UnitCost,  
         (
            CASE 
                WHEN ISNULL(wom.Quantity,0) = 0
                THEN 0
                ELSE
                    wom.BillingAmount
                    /
                    ISNULL(
                        [dbo].[fn_ConvertUOM](
                            ISNULL(wom.Quantity,0),
                            ISNULL(im.[StockUnitOfMeasure],0),
                            ISNULL(im.[ConsumeUnitOfMeasure],0),
                            0,
                            ISNULL(im.[MasterCompanyId],0)
                        ), 0
                    )
            END
        ) AS UnitCost,
	    --(wom.Quantity * (wom.BillingAmount / isnull(wom.Quantity,0))) as extCost  
         (
            ISNULL(
                [dbo].[fn_ConvertUOM](
                    ISNULL(wom.Quantity,0),
                    ISNULL(im.[StockUnitOfMeasure],0),
                    ISNULL(im.[ConsumeUnitOfMeasure],0),
                    0,
                    ISNULL(im.[MasterCompanyId],0)
                ), 0
            )
            *
            (
                CASE 
                    WHEN ISNULL(wom.Quantity,0) = 0
                    THEN 0
                    ELSE
                        wom.BillingAmount
                        /
                        ISNULL(
                            [dbo].[fn_ConvertUOM](
                                ISNULL(wom.Quantity,0),
                                ISNULL(im.[StockUnitOfMeasure],0),
                                ISNULL(im.[ConsumeUnitOfMeasure],0),
                                0,
                                ISNULL(im.[MasterCompanyId],0)
                            ), 0
                        )
                END
            )
        ) AS extCost
	  FROM DBO.WorkOrderQuoteMaterialKitMapping wom WITH(NOLOCK)
	       INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on im.ItemMasterId = wom.ItemMasterId
	       LEFT JOIN [dbo].KitMaster KIM WITH (NOLOCK) ON KIM.KitId = wom.KitId 
	  WHERE wom.WorkflowWorkOrderId = @WorkflowWorkOrderId AND ISNULL(wom.IsDeleted, 0) = 0 AND ISNULL(wom.IsActive, 0) = 1   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQoutePirntMateriallist'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkflowWorkOrderId, '') + '''  
                @Parameter4 = ' + ISNULL(@workOrderPartNoId ,'') +''  
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