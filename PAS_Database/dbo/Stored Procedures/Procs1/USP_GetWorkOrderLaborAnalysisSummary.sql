/*************************************************************           
 ** File:   [USP_GetWorkOrderLaborAnalysisSummary]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used retrieve Work Order Materials List    
 ** Purpose:         
 ** Date:   02/22/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Hemant Saliya		Created
	2    01/19/2022   Hemant Saliya		Update Calculated Values
    3    01/09/2025   Moin Bloch		Update Added StandardHours,StandardMinute,VarianceHours,VarianceMinute
	4    01/29/2025   Moin Bloch		Update SET Hours
	5    07/11/2025   Devendra Shekh    added PartNumberLabel
	6    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0
	7    09/July/2026			 RAJESH GAMI						[PN-17009] - Merge Non-Stock Inventory to Stockline : Get only Stock Inventory Data Where IsNonStock = 0
 EXECUTE USP_GetWorkOrderLaborAnalysisSummary 9752, 0,false
**************************************************************/ 
    
CREATE OR ALTER PROCEDURE [dbo].[USP_GetWorkOrderLaborAnalysisSummary]    
(    
@WorkOrderId BIGINT = NULL,   
@WorkOrderPartNoId BIGINT  = NULL,
@IsDetailView BIT = false
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN  
				if(@workOrderPartNoId = 0)
				BEGIN
				        ;WITH CTE AS(
								SELECT ISNULL(SUM(wfx.EstimatedHours),0) AS AdjustedHours,
								       wo.WorkOrderId
								from dbo.WorkOrderPartNumber wop 
									JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wop.WorkOrderId = wo.WorkOrderId
									JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId
									LEFT JOIN dbo.Workflow wf WITH (NOLOCK) ON wf.WorkflowId = wowf.WorkflowId and wf.WorkScopeId=wop.WorkOrderScopeId
									LEFT JOIN dbo.WorkflowExpertiseList wfx WITH (NOLOCK) ON wfx.WorkflowId = wowf.WorkflowId 
									WHERE wop.WorkOrderId = @WorkOrderId 
									GROUP BY wo.WorkOrderId
			             )
						SELECT 
							im.partnumber AS PartNumber,
							im.PartDescription,
							wop.Id AS WOPartNum,
							im.RevisedPart AS RevisedPN,
							CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
							ISNULL(ISNULL(SUM(wl.[Hours]), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) AS [Hours],
							--ISNULL(ISNULL(SUM(wl.Hours), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) - SUM(ISNULL(CTE.AdjustedHours,0)) AS [Adjustments],
							ISNULL(SUM(wl.Adjustments),0) AS [Adjustments],
							ISNULL(CTE.AdjustedHours,0) AS [AdjustedHours],
							ISNULL(SUM(wl.StandardHours),0) AS StandardHours,
							ISNULL(SUM(wl.StandardMinute),0) AS StandardMinute,
							ISNULL(SUM(wl.VarianceHours),0) AS VarianceHours,	
							ISNULL(SUM(wl.VarianceMinute),0) AS VarianceMinute,
							ISNULL(SUM(wl.BurdenRateAmount),0) AS BurdenRateAmount,
							c.[Name] AS Customer,
							wo.WorkOrderNum,
							ws.Stage,
							st.[Description] AS [Status],
							CASE	WHEN ISNULL(wop.RevisedPartNumber, '') != '' AND ISNULL(wop.RevisedSerialNumber, '') != '' THEN wop.RevisedPartNumber + '-' + wop.RevisedSerialNumber 
									WHEN ISNULL(wop.RevisedPartNumber, '') != '' THEN wop.RevisedPartNumber + '-' + sl.ControlNumber ELSE im.partnumber + '-' + sl.ControlNumber END AS PartNumberLabel
						FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
							JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
							JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
							JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderId = wop.WorkOrderId
							JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
							LEFT JOIN CTE AS CTE WITH (NOLOCK) ON CTE.WorkOrderId = wo.WorkOrderId
							JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
							JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
							JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
							JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON st.Id = wop.WorkOrderStatusId
							LEFT JOIN [dbo].StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
						WHERE wowf.WorkOrderId = @WorkOrderId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 AND BillableId = 1
						 AND ISNULL(im.IsNonStock,0) = 0
						 GROUP BY im.partnumber,im.PartDescription,im.RevisedPart,wop.Id,BillableId,
						 c.[Name],wo.WorkOrderNum,ws.Stage,st.[Description],CTE.AdjustedHours,wop.RevisedPartNumber,wop.RevisedSerialNumber,sl.ControlNumber
					END
					if(@workOrderPartNoId > 0)
					BEGIN   
						 DECLARE @TotalRecord int = 0;   
						 DECLARE @MinId BIGINT = 1;
						 DECLARE @TotalHours DECIMAL(10,2) = 0
						 DECLARE @TotalAdjHours DECIMAL(10,2) = 0						 

						 IF OBJECT_ID(N'tempdb..#WorkOrderLaborAnalysisSummary') IS NOT NULL
						 BEGIN
							DROP TABLE #WorkOrderLaborAnalysisSummary
						 END

						 CREATE TABLE #WorkOrderLaborAnalysisSummary
						 (
							ID BIGINT NOT NULL IDENTITY, 							
							[Hours] DECIMAL(10,2) NULL,
							[Adjustments] DECIMAL(10,2) NULL									
						 )  

						 INSERT INTO #WorkOrderLaborAnalysisSummary ([Hours],[Adjustments])
						 SELECT wl.[Hours],
						        wl.[Adjustments]								
							FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
								JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
								JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID								
							WHERE wowf.WorkOrderId = @WorkOrderId AND wop.ID = @workOrderPartNoId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 AND BillableId = 1

						SELECT @TotalRecord = COUNT(*), @MinId = MIN(ID) FROM #WorkOrderLaborAnalysisSummary    

						WHILE @MinId <= @TotalRecord
						BEGIN	
							DECLARE @Hours  DECIMAL(10,2) = 0
							DECLARE @Adjustments DECIMAL(10,2) = 0
							
							SELECT @Hours = ISNULL([Hours],0),
							       @Adjustments = ISNULL([Adjustments],0)								   		    
							FROM #WorkOrderLaborAnalysisSummary WHERE ID = @MinId	
							
							SET @TotalHours = ISNULL(dbo.CalculateTotalTime(@Hours,@Adjustments),0)

							SET @TotalAdjHours += @TotalHours						
						 
							SET @MinId = @MinId + 1
						END
						
						;WITH CTE AS(
						 	SELECT ISNULL(SUM(wfx.EstimatedHours),0) AS AdjustedHours,wo.WorkOrderId
								FROM  dbo.WorkOrderPartNumber wop 
									JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wop.WorkOrderId = wo.WorkOrderId
									JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId
									LEFT JOIN dbo.Workflow wf WITH (NOLOCK) ON wf.WorkflowId = wowf.WorkflowId and wf.WorkScopeId=wop.WorkOrderScopeId
									LEFT JOIN dbo.WorkflowExpertiseList wfx WITH (NOLOCK) ON wfx.WorkflowId = wowf.WorkflowId 
									WHERE wop.WorkOrderId = @WorkOrderId  AND wop.ID = @workOrderPartNoId 
									GROUP BY wo.WorkOrderId
			                )

							SELECT 
								im.partnumber AS PartNumber,
								im.PartDescription,
								im.RevisedPart AS RevisedPN,
								CASE WHEN wl.BillableId = 1 THEN 'Billable' ELSE 'Non-Billable' END AS BillableOrNonBillable,
								--ISNULL(ISNULL(SUM(wl.[Hours]), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) AS [Hours],
								ISNULL(@TotalAdjHours,0) AS [Hours],
								--ISNULL(ISNULL(SUM(wl.Hours), 0) + ISNULL(SUM(wl.Adjustments), 0), 0) - SUM(ISNULL(CTE.AdjustedHours,0)) AS [Adjustments],
								ISNULL(SUM(wl.Adjustments),0) AS [Adjustments],
							    ISNULL(CTE.AdjustedHours,0) AS [AdjustedHours],
								ISNULL(SUM(wl.StandardHours),0) AS StandardHours,
								ISNULL(SUM(wl.StandardMinute),0) AS StandardMinute,
								ISNULL(SUM(wl.VarianceHours),0) AS VarianceHours,	
								ISNULL(SUM(wl.VarianceMinute),0) AS VarianceMinute,
								ISNULL(SUM(wl.BurdenRateAmount),0) AS BurdenRateAmount,
								c.[Name] AS Customer,
								wo.WorkOrderNum,
								ws.Stage,
								st.[Description] As [Status],
								CASE	WHEN ISNULL(wop.RevisedPartNumber, '') != '' AND ISNULL(wop.RevisedSerialNumber, '') != '' THEN wop.RevisedPartNumber + '-' + wop.RevisedSerialNumber 
										WHEN ISNULL(wop.RevisedPartNumber, '') != '' THEN wop.RevisedPartNumber + '-' + sl.ControlNumber ELSE im.partnumber + '-' + sl.ControlNumber END AS PartNumberLabel
							FROM dbo.WorkOrderLaborHeader wlh WITH (NOLOCK)
								JOIN dbo.WorkOrderLabor wl WITH (NOLOCK) ON wl.WorkOrderLaborHeaderId = wlh.WorkOrderLaborHeaderId
								JOIN dbo.WorkOrderWorkFlow wowf WITH (NOLOCK) ON wlh.WorkFlowWorkOrderId = wowf.WorkFlowWorkOrderId
								JOIN dbo.WorkOrderPartNumber wop WITH (NOLOCK) ON wowf.WorkOrderPartNoId = wop.ID
								JOIN dbo.WorkOrder wo WITH (NOLOCK) ON wlh.WorkOrderId = wo.WorkOrderId
								LEFT JOIN CTE AS CTE WITH (NOLOCK) ON CTE.WorkOrderId = wo.WorkOrderId
								JOIN dbo.WorkOrderStage ws WITH (NOLOCK) ON ws.WorkOrderStageId = wop.WorkOrderStageId
								JOIN dbo.Customer c WITH (NOLOCK) ON c.CustomerId = wo.CustomerId
								JOIN dbo.ItemMaster im WITH (NOLOCK) ON im.ItemMasterId = wop.ItemMasterId
								JOIN dbo.WorkOrderStatus st WITH (NOLOCK) ON st.Id = wop.WorkOrderStatusId
								LEFT JOIN [dbo].StockLine sl WITH(NOLOCK) ON wop.StockLineId = sl.StockLineId AND ISNULL(sl.IsNonStock,0) = 0
							WHERE wowf.WorkOrderId = @WorkOrderId AND wop.ID = @workOrderPartNoId AND wlh.IsDeleted = 0 AND wlh.IsActive = 1 AND BillableId = 1
							 AND ISNULL(im.IsNonStock,0) = 0
							 GROUP BY im.partnumber,im.PartDescription,im.RevisedPart,BillableId,
								c.[Name],wo.WorkOrderNum,ws.Stage,st.[Description],CTE.AdjustedHours,wop.RevisedPartNumber,wop.RevisedSerialNumber,sl.ControlNumber
					END

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				--ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_GetWorkOrderLaborAnalysisData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''', 
													   @Parameter2 = ' + ISNULL(@workOrderPartNoId ,'') +'''
													   @Parameter3 = ' + ISNULL(CAST(@isDetailView AS varchar(10)) ,'') +''
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