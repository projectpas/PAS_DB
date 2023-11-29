
/*************************************************************           
 ** File:   [GetWorkOrderQuoteDetailsForInvioce]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used Get Invoce Details from Quote  
 ** Purpose:         
 ** Date:   05/25/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/25/2021   Hemant Saliya Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
     
-- EXEC [GetWorkOrderQuoteDetailsForInvioce] 81, 83
**************************************************************/

CREATE PROCEDURE [dbo].[GetWorkOrderQuoteDetailsForInvioce]
	@workflowWorkorderId BIGINT,
	@WorkOrderPartNoId BIGINT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				SELECT 
					 WorkOrderQuoteDetailsId,
					 WorkOrderQuoteId,
					 WQD.ItemMasterId,
					 WorkFlowWorkOrderId,
					 WOPartNoId,
					 IM.PartNumber,
					 IM.PartDescription,
					 CASE WHEN BuildMethodId = 1 THEN 'WF' WHEN BuildMethodId = 2 THEN 'WO' WHEN BuildMethodId = 3 THEN 'WF' ELSE 'Third Party' END AS BuildMethod,
					 BuildMethodId,
                     MaterialCost,
					 MaterialBilling,
					 LaborCost,
					 LaborBilling,
					 ChargesCost,
					 ChargesBilling,
					 FreightCost,
					 FreightBilling,
                     LaborFlatBillingAmount,
                     MaterialFlatBillingAmount,
                     ChargesFlatBillingAmount,
                     FreightFlatBillingAmount,
                     MaterialBuildMethod,
                     LaborBuildMethod,
                     ChargesBuildMethod,
                     FreightBuildMethod,
                     MaterialMarkupId,
                     LaborMarkupId,
                     ChargesMarkupId,
                     FreightMarkupId,
                     ExclusionsMarkupId,
					 QuoteMethod,
					 CommonFlatRate
				FROM DBO.WorkOrderQuoteDetails WQD  WITH(NOLOCK) 
				LEFT JOIN dbo.ItemMaster IM WITH(NOLOCK) ON IM.ItemMasterId = WQD.ItemMasterId
				WHERE WorkflowWorkOrderId = @workflowWorkorderId AND WOPartNoId = @WorkOrderPartNoId AND IsVersionIncrease = 0
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderQuoteBuildMethodDetails' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workflowWorkorderId, '') + '''
													   @Parameter2 = ' + ISNULL(@WorkOrderPartNoId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END