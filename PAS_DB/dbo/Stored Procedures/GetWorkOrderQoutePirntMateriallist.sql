﻿
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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    06/02/2020   Subhash Saliya Created
     
--EXEC [GetWorkOrderPrintPdfData] 274,258
**************************************************************/

CREATE PROCEDURE [dbo].[GetWorkOrderQoutePirntMateriallist]
@WorkflowWorkOrderId bigint,
@workOrderPartNoId bigint
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT  mt.Quantity,
				        mt.UomName,
						mt.PartNumber as partnumber,
						mt.PartDescription as PartDescription,
						mt.UnitCost as UnitCost,
					    (mt.Quantity * isnull(mt.UnitCost,0)) as extCost
				FROM WorkOrderQuoteMaterial mt WITH(NOLOCK)  
					INNER JOIN WorkOrderQuoteDetails wop WITH(NOLOCK) on wop.WorkOrderQuoteDetailsId = mt.WorkOrderQuoteDetailsId 
					LEFT JOIN ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = mt.ItemMasterId
				WHERE wop.WorkflowWorkOrderId = @WorkflowWorkOrderId 
			END
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