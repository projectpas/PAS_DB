
-- ---------------------------------------------------------------------------------------------------
-- Stored Procedure: dbo.GetWorkOrderQuoteBuildMethodDetails   (source: PAS_DB/dbo/Stored Procedures/Procs1/GetWorkOrderQuoteBuildMethodDetails.sql)
-- ---------------------------------------------------------------------------------------------------
/*************************************************************             
 ** File:   [GetWorkOrderQuoteBuildMethodDetails]             
 ** Author:   Hemant Saliya  
 ** Description: This stored procedure is used Get WorkOrder Quote Build Method Details    
 ** Purpose:           
 ** Date:   05/25/2021          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    05/25/2021   Hemant Saliya Created  
	2    11/12/2025   Moin Bloch    Updated For MRO Price Flag   
	3    13/12/2025  Moin Bloch     Updated (Added Opr)
	4    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
       
-- EXEC [GetWorkOrderQuoteBuildMethodDetails] 29871  
**************************************************************/  
  
CREATE     PROCEDURE [dbo].[GetWorkOrderQuoteBuildMethodDetails]  
@workflowWorkorderId BIGINT  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN  
    DECLARE @ItemMasterId BIGINT=0,@MasterCompanyId INT = 0,@WorkOrderScopeId BIGINT=0,@CustomerId BIGINT=0,@UnitPrice DECIMAL(18,2)=0,@Opr INT=2

	IF OBJECT_ID(N'tempdb..#MROPriceResult') IS NOT NULL
	BEGIN
		DROP TABLE #MROPriceResult
	END

	SELECT TOP 1 @ItemMasterId = WQD.[ItemMasterId], 	             
				 @WorkOrderScopeId = WOP.[WorkOrderScopeId],
				 @CustomerId = WOQ.[CustomerId],
				 @MasterCompanyId = WQD.[MasterCompanyId]
	FROM [dbo].[WorkOrderQuoteDetails] WQD WITH(NOLOCK)  
	INNER JOIN  [dbo].[WorkOrderPartNumber] WOP WITH(NOLOCK) ON WQD.WOPartNoId = WOP.ID
	INNER JOIN  [dbo].[WorkOrderQuote] WOQ WITH(NOLOCK) ON WQD.WorkOrderQuoteId = WOQ.WorkOrderQuoteId
	WHERE WQD.[WorkflowWorkOrderId] = @workflowWorkorderId AND ISNULL(WQD.[IsVersionIncrease],0) = 0 

	CREATE TABLE #MROPriceResult ([UnitPrice] DECIMAL(18,2) NULL);
	INSERT INTO #MROPriceResult
    EXEC [dbo].[USP_GetMROPriceForWorkOrderQuote] @ItemMasterId,@WorkOrderScopeId,@CustomerId,@MasterCompanyId,@Opr

	SELECT @UnitPrice = ISNULL([UnitPrice],0) FROM #MROPriceResult

    SELECT   
		WQD.[ItemMasterId],  
		IM.[PartNumber],  
		CASE WHEN [BuildMethodId] = 1 THEN 'WF' WHEN [BuildMethodId] = 2 THEN 'WO' WHEN [BuildMethodId] = 3 THEN 'WF' ELSE 'Third Party' END AS [BuildMethod],  
		[BuildMethodId],  
		[WorkOrderQuoteDetailsId],  
		[LaborFlatBillingAmount],  
		[MaterialFlatBillingAmount],  
		[ChargesFlatBillingAmount],  
		[FreightFlatBillingAmount],  
		[MaterialBuildMethod],  
		[LaborBuildMethod],  
		[ChargesBuildMethod],  
		[FreightBuildMethod],  
		[MaterialMarkupId],  
		[LaborMarkupId],  
		[ChargesMarkupId],  
		[FreightMarkupId],  
		[ExclusionsMarkupId],  
        [CommonFlatRate],  
        [QuoteMethod],
		[EvalFees],
		CASE WHEN @UnitPrice > 0 THEN 1 ELSE 0 END [IsMroPrice]
    FROM DBO.WorkOrderQuoteDetails WQD WITH (NOLOCK)  
     LEFT JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WQD.ItemMasterId  
     AND ISNULL(IM.IsNonStock,0) = 0
      WHERE WQD.WorkflowWorkOrderId = @workflowWorkorderId AND ISNULL(IsVersionIncrease,0) = 0  

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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workflowWorkorderId, '') + ''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName           =  @DatabaseName  
                     , @AdhocComments          =  @AdhocComments  
                     , @ProcedureParameters    =  @ProcedureParameters  
                     , @ApplicationName        =  @ApplicationName  
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END