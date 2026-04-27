
/*************************************************************           
 ** File:   [USP_AddEdit_WorkOrderTurnArroundTime]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA   
 ** Purpose:         
 ** Date:   12/22/2022        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/22/2022   Subhash Saliya		Created
	2	 03/08/2024   Bhargav Saliya     Change Order By Desc to Asc
	3	 06/24/2024   Abhishek Jirawla   Adding memo
	4	 01/16/2025	  Moin Bloch		 Modified (Added TaskId For Kit)
	5	 01/17/2025	  Moin Bloch		 Modified (Added @WorkOrderFormTypeId from WO Kit)
	6	 02/10/2025	  Moin Bloch		 Modified (Added condition @WorkOrderQuoteDetailsId in [WorkOrderQuoteDetails] from duplicate WO Kit)
	7	 02/10/2025	  Abhishek Jirawla	 Added Billing Name
	8	 07/01/2026	  Rajesh Gami    	 Getting QTY and COST based on ItemMaster ConsumeUOM
	9    08/01/2026   Rajesh Gami		 Added MasterCompanyId Parameter While Calling UOM Conversion Function
	10   09/04/2026   Ayushi Patel	     PN-15909 resolved uom convertion issue for UnitPrice 
	11   24/04/2026   Ayushi Patel		 PN-15982 Removed ROUND , as it was causing the mismatch in unitPrice
-- EXEC [USP_GetWorkOrderQuoteMaterial] 1575,4,0,0
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_GetWorkOrderQuoteMaterial]
	 @workOrderQuoteDetailsId bigint,  
	 @buildMethodId bigint,  
	 @loweUnitrCostVal bigint ,
	 @upperUnitCostVal bigint = null
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		--BEGIN TRANSACTION
		--	BEGIN  

			DECLARE @WorkflowWorkOrderId BIGINT = 0
			DECLARE @WorkOrderQuoteId BIGINT = 0			
			DECLARE @WorkOrderId BIGINT = 0
			DECLARE @WorkOrderFormTypeId BIT = 0; 			

			SELECT @WorkflowWorkOrderId=WorkflowWorkOrderId,@WorkOrderQuoteId=WorkOrderQuoteId FROM dbo.WorkOrderQuoteDetails WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId= @workOrderQuoteDetailsId

			SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[WorkOrderQuote] WITH(NOLOCK) WHERE [WorkOrderQuoteId] = @WorkOrderQuoteId

			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH (NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
			
		   IF OBJECT_ID('tempdb..#tmpWorkOrderQuoteMat') IS NOT NULL
			DROP TABLE #tmpWorkOrderQuoteMat;

			SELECT * INTO #tmpWorkOrderQuoteMat
			FROM (
			SELECT      im.PartNumber,
                        im.PartDescription,
                        im.ManufacturerName,
						'' as AltPartNumber,
						CASE WHEN wq.BuildMethodId = 1 THEN 'WF' WHEN wq.BuildMethodId = 2  THEN 'WO'  WHEN wq.BuildMethodId = 3  THEN 'WF' ELSE 'Third Party' END Source,
						dbo.fn_ConvertUOM(wom.Quantity, uomStock.ShortName, uomConsume.ShortName,0,wom.MasterCompanyId) as Quantity,
						1 as Partqty,
                        --wom.UnitOfMeasureId,
                        --uom.ShortName as UOM,
						im.ConsumeUnitOfMeasureId AS UnitOfMeasureId,
                        uomConsume.ShortName as UOM,
                        wom.ConditionCodeId,
                        c.Description as Condition,
					   (CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER'
										 WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' 
					                     WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER' 
										 ELSE 'OEM'
									END)  as StockType,
						dbo.fn_ConvertUOM(wom.UnitCost, uomStock.ShortName, uomConsume.ShortName,1,wom.MasterCompanyId) as UnitCost,
                        wom.MarkupPercentageId,
                        wom.WorkOrderQuoteDetailsId,
                        wom.WorkOrderQuoteMaterialId,
                        wom.ItemClassificationId,
                        wom.ItemMasterId,
                       wom.TaskId,
					   --ts.Description as TaskName,
					   CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE ts.[Description] END AS TaskName,
					   wom.MarkupFixedPrice,
                       wom.BillingMethodId,
					   wom.BillingName,
                       wom.HeaderMarkupId,
                       wom.ExtendedCost,
                       wom.BillingRate,
                       wom.BillingAmount,
                       ms.Name as MandatoryOrSupplemental,
                       wom.MaterialMandatoriesId,
                       wom.MasterCompanyId,
					   ic.Description as ItemClassification,
					   wom.IsDefered,
					   wom.ProvisionId,
					   p.Description as Provision,
					   im.Figure,
                       im.Item,
					   0 as WOQMaterialKitMappingId,
					   0 as KitId,
					   ISNULL(wom.Memo, '') AS 'Memo',
					   wom.CreatedBy,
					   wom.CreatedDate,
					   wom.UpdatedBy,
					   wom.UpdatedDate,
					   wom.IsActive,
					   wom.IsDeleted,
					   per.PercentValue as MarkUp
				FROM [dbo].[WorkOrderQuoteMaterial] wom WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderQuoteDetails] wq  WITH(NOLOCK) ON wq.WorkOrderQuoteDetailsId = wom.WorkOrderQuoteDetailsId
					INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON im.ItemMasterId = wom.ItemMasterId
					 LEFT JOIN [dbo].[Provision] p WITH(NOLOCK) ON p.ProvisionId = wom.ProvisionId
					 LEFT JOIN [dbo].[Condition] c WITH(NOLOCK) ON c.ConditionId = wom.ConditionCodeId
					 LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON uom.UnitOfMeasureId = wom.UnitOfMeasureId
					 LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = im.StockUnitOfMeasureId
					 LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = im.ConsumeUnitOfMeasureId
					 LEFT JOIN [dbo].[ItemClassification] ic WITH(NOLOCK) ON ic.ItemClassificationId = wom.ItemClassificationId
					 LEFT JOIN [dbo].[Task] ts  WITH(NOLOCK) ON ts.TaskId = wom.TaskId
					 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = WOM.TaskId
					 LEFT JOIN [dbo].[MaterialMandatories] ms  WITH(NOLOCK) ON ms.Id = wom.MaterialMandatoriesId
					INNER JOIN [dbo].[WorkOrderWorkFlow] wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = wq.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wfwo.WorkOrderPartNoId = wop.ID 
					LEFT JOIN dbo.[Percent] per WITH(NOLOCK) ON per.PercentId = wom.MarkupPercentageId
				WHERE wom.WorkOrderQuoteDetailsId = @workOrderQuoteDetailsId AND wom.IsDeleted = 0  and ((@loweUnitrCostVal = 0 and @upperUnitCostVal=0) or ( (wom.UnitCost >= @loweUnitrCostVal and wom.UnitCost <= @upperUnitCostVal)) ) --order by wom.CreatedDate desc

				UNION ALL
				 
				 SELECT 
					    wom.KitNumber as PartNumber,
                        KIM.KitDescription as PartDescription,
                        '' as ManufacturerName,
						'' as AltPartNumber,
						case when wq.BuildMethodId = 1 then 'WF' when wq.BuildMethodId = 2  then 'WO'  when wq.BuildMethodId = 3  then 'WF' else 'Third Party' end Source,
						dbo.fn_ConvertUOM(wom.Quantity, uomStock.ShortName, uomConsume.ShortName,0,wom.MasterCompanyId) as Quantity,
						dbo.fn_ConvertUOM(wom.Quantity, uomStock.ShortName, uomConsume.ShortName,0,wom.MasterCompanyId) as Partqty,
                        im.ConsumeUnitOfMeasureId as UnitOfMeasureId,
                        '' as UOM,
                        0 as ConditionCodeId,
                        '' as Condition,
					    ''  as StockType,
						dbo.fn_ConvertUOM(wom.UnitCost, uomStock.ShortName, uomConsume.ShortName,1,wom.MasterCompanyId)  AS UnitCost,
                        wom.MarkupPercentageId,
                        wq.WorkOrderQuoteDetailsId as WorkOrderQuoteDetailsId,
                        0 as WorkOrderQuoteMaterialId,
                        im.ItemClassificationId as ItemClassificationId,
                        wom.ItemMasterId,
                       wom.TaskId,
					   --'' as TaskName,
					   CASE WHEN @WorkOrderFormTypeId = 1 THEN WOT.[TaskName] ELSE ts.[Description] END AS TaskName,
					   wom.MarkupFixedPrice,
                       wom.BillingMethodId,
                       wom.BillingName,
                       wom.HeaderMarkupId,
                       wom.ExtendedCost,
                       wom.BillingRate,
                       wom.BillingAmount,
                       '' as MandatoryOrSupplemental,
                       0 as MaterialMandatoriesId,
                       wom.MasterCompanyId,
					   ic.Description as ItemClassification,
					   0 as IsDefered,
					   im.ProvisionId as ProvisionId,
					   p.Description as Provision,
					   im.Figure,
                       im.Item,
					   wom.WOQMaterialKitMappingId as WOQMaterialKitMappingId,
					   wom.kitId as KitId,
					   '' AS Memo,
					   wom.CreatedBy,
					   wom.CreatedDate,
					   wom.UpdatedBy,
					   wom.UpdatedDate,
					   wom.IsActive,
					   wom.IsDeleted,
					   per.PercentValue as MarkUp
				FROM [dbo].[WorkOrderQuoteMaterialKitMapping] wom WITH(NOLOCK)
					 LEFT JOIN [dbo].[WorkOrderQuoteDetails] wq  WITH(NOLOCK) ON wq.WorkOrderQuoteId = wom.WorkOrderQuoteId AND wq.WorkOrderQuoteDetailsId = @workOrderQuoteDetailsId
					INNER JOIN [dbo].[ItemMaster] im WITH(NOLOCK) ON im.ItemMasterId = wom.ItemMasterId
					 LEFT JOIN [dbo].[Provision] p WITH(NOLOCK) ON p.ProvisionId = im.ProvisionId
					 LEFT JOIN [dbo].[KitMaster] KIM WITH (NOLOCK) ON KIM.KitId = wom.KitId 
					 LEFT JOIN [dbo].[UnitOfMeasure] uom WITH(NOLOCK) ON uom.UnitOfMeasureId = im.StockUnitOfMeasureId
					 LEFT JOIN [dbo].[UnitOfMeasure] uomStock WITH(NOLOCK) ON uomStock.UnitOfMeasureId = im.StockUnitOfMeasureId
					 LEFT JOIN [dbo].[UnitOfMeasure] uomConsume WITH(NOLOCK) ON uomConsume.UnitOfMeasureId = im.ConsumeUnitOfMeasureId
					 LEFT JOIN [dbo].[ItemClassification] ic WITH(NOLOCK) ON ic.ItemClassificationId = im.ItemClassificationId
					 LEFT JOIN [dbo].[Task] ts  WITH(NOLOCK) ON ts.TaskId = wom.TaskId
					 LEFT JOIN [dbo].[WorkOrderTask] WOT WITH (NOLOCK) ON WOT.WorkOrderTaskId = wom.TaskId
					INNER JOIN [dbo].[WorkOrderWorkFlow] wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = wq.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK) ON wfwo.WorkOrderPartNoId = wop.ID 
					LEFT JOIN dbo.[Percent] per WITH(NOLOCK) ON per.PercentId = wom.MarkupPercentageId
				WHERE wom.WorkflowWorkOrderId = @WorkflowWorkOrderId  AND wom.WorkOrderQuoteId = @WorkOrderQuoteId AND wom.IsDeleted = 0  AND ((@loweUnitrCostVal = 0 AND @upperUnitCostVal=0) or ( (wom.UnitCost >= @loweUnitrCostVal AND wom.UnitCost <= @upperUnitCostVal)) )
                ) t;

				UPDATE #tmpWorkOrderQuoteMat 
					SET ExtendedCost =ISNULL(Quantity,0) * ISNULL(UnitCost,0),
						BillingAmount = ((ISNULL(UnitCost,0) * ISNULL(Quantity,0)) * ISNULL(MarkUp,0)) / 100
												+ (ISNULL(UnitCost,0) * ISNULL(Quantity,0)),
						BillingRate = ((ISNULL(UnitCost,0) * ISNULL(MarkUp,0)) / 100) + ISNULL(UnitCost,0)
				Select * From #tmpWorkOrderQuoteMat  order by CreatedDate asc
		--	END
		--COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				--PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateTravelerSetupHeader' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderQuoteDetailsId, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END