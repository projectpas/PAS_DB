
/*************************************************************           
 ** File:   [WorkOrderQuoteSummarizedHistoryByCustomer]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used WO Quote Summarized History By Customer.    
 ** Purpose: This stored procedure is used WO Quote Summarized History.        
 ** Date:   07/13/2021        
          
 ** PARAMETERS:           
 @@WorkOrderId BIGINT
 @WorkOrderPartNumberId BIGINT
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    07/13/2021   Hemant Saliya Created
     
--EXEC [WorkOrderQuoteSummarizedHistoryByCustomer] 295,0
**************************************************************/

CREATE PROCEDURE [dbo].[WorkOrderQuoteSummarizedHistoryByCustomer]
@ItemMasterId BIGINT,
@IsTwelveMonth BIT = 1
AS
BEGIN
	   SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	   SET NOCOUNT ON;

		BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					DECLARE @Month INT;

					IF(@IsTwelveMonth = 1)
					BEGIN
						SET @Month = 12
					END
					ELSE
					BEGIN
						SET @Month = 18
					END
					SELECT 
						WO.CustomerName,
						WO.WorkOrderNum,
						WO.OpenDate,
						WO.WorkOrderId,
						WOQ.WorkOrderQuoteId,
						WOSG.Code + '-' + WOSG.Stage AS  Stage,
						WOS.Description AS WorkOrderStatus,
						WOQ.QuoteNumber,
						WS.WorkScopeCode AS WorkScope,
						WS.WorkScopeId,
						C.Code AS CurrencyName,
						(ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) AS Revenue,
						(ISNULL(WOQD.MaterialCost, 0) + ISNULL(WOQD.LaborCost, 0) + ISNULL(WOQD.ChargesCost, 0)) AS DirectCost,
						(ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) -  (ISNULL(WOQD.MaterialCost, 0) + ISNULL(WOQD.LaborCost, 0) + ISNULL(WOQD.ChargesCost, 0)) As Margin,
						CASE WHEN (ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) > 0 
							 THEN (((ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0)) -  (ISNULL(WOQD.MaterialCost, 0) + ISNULL(WOQD.LaborCost, 0) + ISNULL(WOQD.ChargesCost, 0))) / (ISNULL(WOQD.MaterialFlatBillingAmount, 0) + ISNULL(WOQD.LaborFlatBillingAmount, 0) + ISNULL(WOQD.ChargesFlatBillingAmount, 0) + ISNULL(WOQD.FreightFlatBillingAmount, 0))) * 100
						ELSE 0 END AS MarginPercentage,
						CASE WHEN UPPER(WOQS.Description) = 'APPROVED' THEN 'YES' ELSE 'NO' END AS ApprovedStatus
					FROM dbo.WorkOrder WO WITH(NOLOCK) 
						JOIN dbo.WorkOrderQuote WOQ WITH(NOLOCK) ON WO.WorkOrderId = WOQ.WorkOrderId
						JOIN dbo.WorkOrderQuoteDetails WOQD WITH(NOLOCK) ON WOQD.WorkOrderQuoteId = WOQ.WorkOrderQuoteId AND WOQD.IsVersionIncrease = 0
						JOIN dbo.WorkOrderPartNumber WOP WITH(NOLOCK) ON WOP.ID = WOQD.WOPartNoId
						JOIN dbo.ItemMaster IM WITH(NOLOCK) ON WOP.ItemMasterId = IM.ItemMasterId
						JOIN dbo.WorkScope WS WITH (NOLOCK) ON WS.WorkScopeId = WOP.WorkOrderScopeId
						JOIN dbo.WorkOrderQuoteStatus WOQS WITH (NOLOCK) ON WOQS.WorkOrderQuoteStatusId = WOQ.QuoteStatusId 
						JOIN dbo.WorkOrderStage WOSG WITH(NOLOCK) ON WOP.WorkOrderStageId = WOSG.WorkOrderStageId	
						JOIN dbo.WorkOrderStatus WOS WITH(NOLOCK) ON WOS.Id = WO.WorkOrderStatusId
						--LEFT JOIN dbo.WorkOrderApproval WAP WITH (NOLOCK) ON WAP.WorkOrderQuoteId = WOQ.WorkOrderQuoteId
						LEFT JOIN dbo.Currency C WITH (NOLOCK) ON C.CurrencyId = WOQ.CurrencyId						
					WHERE IM.ItemMasterId = @ItemMasterId AND DATEDIFF(MM, WOQ.createdDate, GETDATE()) < @Month 
					--GROUP BY IM.partnumber, WOP.ItemMasterId, WS.WorkScopeCode, WS.WorkScopeId ,C.Code
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'WorkOrderQuoteSummarizedHistoryByMPN' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(CAST(@IsTwelveMonth AS VARCHAR(10)), '') + ''',
													   @Parameter2 = ' + ISNULL(@ItemMasterId ,'') +''
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