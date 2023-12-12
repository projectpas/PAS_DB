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
		BEGIN TRANSACTION
			BEGIN  

			DECLARE @WorkflowWorkOrderId BIGINT = 0
			DECLARE @WorkOrderQuoteId BIGINT = 0

			SELECT @WorkflowWorkOrderId=WorkflowWorkOrderId,@WorkOrderQuoteId=WorkOrderQuoteId FROM DBO.WorkOrderQuoteDetails WITH(NOLOCK) WHERE WorkOrderQuoteDetailsId= @workOrderQuoteDetailsId

				 SELECT 
					    im.PartNumber,
                        im.PartDescription,
                        im.ManufacturerName,
						'' as AltPartNumber,
						CASE WHEN wq.BuildMethodId = 1 THEN 'WF' WHEN wq.BuildMethodId = 2  THEN 'WO'  WHEN wq.BuildMethodId = 3  THEN 'WF' ELSE 'Third Party' END Source,
						wom.Quantity,
						1 as Partqty,
                        wom.UnitOfMeasureId,
                        uom.ShortName as UOM,
                        wom.ConditionCodeId,
                        c.Description as Condition,
					   (CASE WHEN im.IsPma = 1 AND im.IsDER = 1 THEN 'PMA&DER'
										 WHEN im.IsPma = 1 AND im.IsDER = 0 THEN 'PMA' 
					                     WHEN im.IsPma = 0 AND im.IsDER = 1  THEN 'DER' 
										 ELSE 'OEM'
									END)  as StockType,
						wom.UnitCost,
                        wom.MarkupPercentageId,
                        wom.WorkOrderQuoteDetailsId,
                        wom.WorkOrderQuoteMaterialId,
                        wom.ItemClassificationId,
                        wom.ItemMasterId,
                       wom.TaskId,
					   ts.Description as TaskName,
					   wom.MarkupFixedPrice,
                       wom.BillingMethodId,
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
					   wom.CreatedBy,
					   wom.CreatedDate,
					   wom.UpdatedBy,
					   wom.UpdatedDate,
					   wom.IsActive,
					   wom.IsDeleted
				FROM DBO.WorkOrderQuoteMaterial wom WITH(NOLOCK)
					INNER JOIN DBO.WorkOrderQuoteDetails wq  WITH(NOLOCK) on wq.WorkOrderQuoteDetailsId = wom.WorkOrderQuoteDetailsId
					INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on im.ItemMasterId = wom.ItemMasterId
					LEFT JOIN DBO.Provision p WITH(NOLOCK) on p.ProvisionId = wom.ProvisionId
					LEFT JOIN DBO.Condition c WITH(NOLOCK) on c.ConditionId = wom.ConditionCodeId
					LEFT JOIN DBO.UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = wom.UnitOfMeasureId
					LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) on ic.ItemClassificationId = wom.ItemClassificationId
					LEFT JOIN DBO.Task ts  WITH(NOLOCK) on ts.TaskId = wom.TaskId
					LEFT JOIN DBO.MaterialMandatories ms  WITH(NOLOCK) on ms.Id = wom.MaterialMandatoriesId
					INNER JOIN DBO.WorkOrderWorkFlow wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = wq.WorkFlowWorkOrderId 
					INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) ON wfwo.WorkOrderPartNoId = wop.ID 
				WHERE wom.WorkOrderQuoteDetailsId = @workOrderQuoteDetailsId AND wom.IsDeleted = 0  and ((@loweUnitrCostVal = 0 and @upperUnitCostVal=0) or ( (wom.UnitCost >= @loweUnitrCostVal and wom.UnitCost <= @upperUnitCostVal)) ) --order by wom.CreatedDate desc

				UNION ALL
				 
				 SELECT 
					    wom.KitNumber as PartNumber,
                        KIM.KitDescription as PartDescription,
                        '' as ManufacturerName,
						'' as AltPartNumber,
						case when wq.BuildMethodId = 1 then 'WF' when wq.BuildMethodId = 2  then 'WO'  when wq.BuildMethodId = 3  then 'WF' else 'Third Party' end Source,
						wom.Quantity as Quantity,
						wom.Quantity as Partqty,
                        im.StockUnitOfMeasureId as UnitOfMeasureId,
                        '' as UOM,
                        0 as ConditionCodeId,
                        '' as Condition,
					    ''  as StockType,
						wom.UnitCost,
                        wom.MarkupPercentageId,
                        wq.WorkOrderQuoteDetailsId as WorkOrderQuoteDetailsId,
                        0 as WorkOrderQuoteMaterialId,
                        im.ItemClassificationId as ItemClassificationId,
                        wom.ItemMasterId,
                       0 as TaskId,
					   '' as TaskName,
					   wom.MarkupFixedPrice,
                       wom.BillingMethodId,
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
					   wom.CreatedBy,
					   wom.CreatedDate,
					   wom.UpdatedBy,
					   wom.UpdatedDate,
					   wom.IsActive,
					   wom.IsDeleted
				FROM DBO.WorkOrderQuoteMaterialKitMapping wom WITH(NOLOCK)
					LEFT JOIN DBO.WorkOrderQuoteDetails wq  WITH(NOLOCK) on wq.WorkOrderQuoteId = wom.WorkOrderQuoteId
					INNER JOIN DBO.ItemMaster im WITH(NOLOCK) on im.ItemMasterId = wom.ItemMasterId
					LEFT JOIN DBO.Provision p WITH(NOLOCK) on p.ProvisionId = im.ProvisionId
					LEFT JOIN [dbo].KitMaster KIM WITH (NOLOCK) ON KIM.KitId = wom.KitId 
					LEFT JOIN DBO.UnitOfMeasure uom WITH(NOLOCK) on uom.UnitOfMeasureId = im.StockUnitOfMeasureId
					LEFT JOIN DBO.ItemClassification ic WITH(NOLOCK) on ic.ItemClassificationId = im.ItemClassificationId
					--LEFT JOIN DBO.Task ts  WITH(NOLOCK) on ts.TaskId = wom.TaskId
					--LEFT JOIN DBO.MaterialMandatories ms  WITH(NOLOCK) on ms.Id = wom.MaterialMandatoriesId
					INNER JOIN DBO.WorkOrderWorkFlow wfwo WITH(NOLOCK) ON wfwo.WorkFlowWorkOrderId = wq.WorkFlowWorkOrderId 
					INNER JOIN DBO.WorkOrderPartNumber wop WITH(NOLOCK) ON wfwo.WorkOrderPartNoId = wop.ID 
				WHERE wom.WorkflowWorkOrderId = @WorkflowWorkOrderId  and wom.WorkOrderQuoteId = @WorkOrderQuoteId AND wom.IsDeleted = 0  and ((@loweUnitrCostVal = 0 and @upperUnitCostVal=0) or ( (wom.UnitCost >= @loweUnitrCostVal and wom.UnitCost <= @upperUnitCostVal)) ) order by wom.CreatedDate desc
                
			END
		COMMIT  TRANSACTION

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