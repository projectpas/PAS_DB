/*************************************************************           
 ** File:   [USP_GetSubWorkOrderLaborAnalysisSummary]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve sub Work Order Labor Analysis Summary    
 ** Purpose:         
 ** Date:   06/18/2021        
          
 ** PARAMETERS:           
 @SubWorkOrderPartNoId BIGINT   
 @IsDetailView BIT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author			Change Description            
 ** --   --------     -------			--------------------------------          
    1    06/18/2021   Hemant Saliya		Created
    2    12/22/2021   Devendra Shekh	added SubWorkOrderNo to select
     
 EXECUTE USP_GetSubWorkOrderLaborAnalysisSummary 331,122, 0

**************************************************************/ 
    
CREATE   PROCEDURE [dbo].[USP_GetSubWorkOrderLaborAnalysisSummary]    
(    
@WorkOrderId BIGINT = NULL, 
@SubWorkOrderPartNoId BIGINT  = NULL,
@IsDetailView BIT = false
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				SELECT 
					im.partnumber AS PartNumber,
					im.PartDescription,
					wop.SubWOPartNoId AS WOPartNum,
					im.RevisedPart AS RevisedPN,
					CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
					SUM(wl.Hours) AS [Hours],
					SUM(wl.Adjustments) AS [Adjustments],
					SUM(wl.AdjustedHours) AS [AdjustedHours],
					SUM(wl.BurdenRateAmount) AS BurdenRateAmount,
					c.Name AS Customer,
					wo.WorkOrderNum,
					swo.SubWorkOrderNo,
					ws.Stage,
					st.[Description] As [Status]
				FROM dbo.SubWorkOrderLaborHeader wlh WITH (NOLOCK)
				JOIN dbo.SubWorkOrderLabor wl WITH (NOLOCK) ON wl.SubWorkOrderLaborHeaderId = wlh.SubWorkOrderLaborHeaderId
				JOIN dbo.SubWorkOrderPartNumber wop WITH (NOLOCK) ON wlh.SubWOPartNoId = wop.SubWOPartNoId
				JOIN dbo.SubWorkOrder swo WITH (NOLOCK) ON wlh.SubWorkOrderId = swo.SubWorkOrderId
				JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wop.WorkOrderId
				JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.SubWorkOrderStageId
				JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
				JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
				JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON st.Id = wop.SubWorkOrderStatusId
				WHERE wlh.SubWOPartNoId = @SubWorkOrderPartNoId AND wo.WorkOrderId = @WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 AND BillableId = 1
				GROUP BY im.partnumber,im.PartDescription,im.RevisedPart,BillableId, wop.SubWOPartNoId,
					c.Name,wo.WorkOrderNum,ws.Stage,st.[Description],swo.SubWorkOrderNo		
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetSubWorkOrderLaborAnalysisData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SubWorkOrderPartNoId, '') + ''', 
													   @Parameter2 = ' + ISNULL(CAST(@isDetailView AS varchar(10)) ,'') +''
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