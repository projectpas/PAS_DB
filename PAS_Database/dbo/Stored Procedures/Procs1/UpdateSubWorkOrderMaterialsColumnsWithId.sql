
/*************************************************************           
 ** File:   [UpdateWorkOrderTeardownColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Update SubWorkOrderMaterials 
 ** Purpose:         
 ** Date:   04/30/2021       
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04/30/2021    Subhash Saliya Created
    2    04/30/2021    Subhash Saliya Changes Lower data
	3    05/15/2021    Hemant  Saliya Update Join & Added Contect Mangment
	4	 01/20/2024	   Moin Bloch	  Modified (Added WorkOrderTask Table For conditionally check table for Task)
	5    01/July/2026			 RAJESH GAMI						[PN-17008] - Merge Non Stock Inventory to ItemMaster : Get only Stock Inventory Data Where IsNonStock = 0

     
--EXEC [UpdateSubWorkOrderMaterialsColumnsWithId] subworkordermaterial,28
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateSubWorkOrderMaterialsColumnsWithId]
	@SubWorkOrderMaterialsId bigint
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN 
				DECLARE @WorkOrderId BIGINT = 0;
				DECLARE @WorkOrderFormTypeId BIT = 0; 
				
				SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[SubWorkOrderMaterials] WITH (NOLOCK) WHERE [SubWorkOrderMaterialsId] = @SubWorkOrderMaterialsId;

             	SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK)	WHERE WO.[WorkOrderId] = @WorkOrderId;
							   				
				UPDATE WOM SET 
						WOM.[Site] =IM.SiteName,
						WOM.WareHouse =IM.WarehouseName,
						WOM.Locations =IM.LocationName,
						WOM.Shelf =IM.ShelfName,
						WOM.Bin =IM.BinName,
						WOM.Condition = C.[Description], 
						WOM.Provision = P.[Description],
						WOM.TaskName = CASE WHEN @WorkOrderFormTypeId = 1 THEN WT.[TaskName] ELSE T.[Description] END,
						WOM.ItemClassification =ITC.[Description],
						WOM.UOM=UOM.ShortName 
					FROM dbo.SubWorkOrderMaterials WOM WITH (NOLOCK)  
						JOIN dbo.ItemMaster IM WITH (NOLOCK) ON IM.ItemMasterId = WOM.ItemMasterId
						JOIN dbo.UnitOfMeasure UOM WITH (NOLOCK) ON UOM.UnitOfMeasureId = IM.PurchaseUnitOfMeasureId
						JOIN dbo.Condition C WITH (NOLOCK) ON C.ConditionId = WOM.ConditionCodeId
						JOIN dbo.ItemClassification ITC WITH (NOLOCK) ON ITC.ItemClassificationId = IM.ItemClassificationId
						JOIN dbo.Provision P WITH (NOLOCK) ON P.ProvisionId = WOM.ProvisionId
						LEFT JOIN dbo.Task T WITH (NOLOCK) ON T.TaskId = WOM.TaskId
						LEFT JOIN dbo.WorkOrderTask WT WITH (NOLOCK) ON WT.WorkOrderTaskId = WOM.TaskId
					WHERE WOM.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
			 AND ISNULL(IM.IsNonStock,0) = 0
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateSubWorkOrderMaterialsColumnsWithId' 
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@SubWorkOrderMaterialsId, '') AS VARCHAR(100))  
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