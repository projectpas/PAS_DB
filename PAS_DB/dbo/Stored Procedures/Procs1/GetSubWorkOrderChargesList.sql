/*************************************************************           
 ** File:   [GetSubWorkOrderChargesList]           
 ** Author:   
 ** Description: This stored procedure is used TO GetSubWorkOrderChargesList
 ** Purpose:         
 ** Date:        
          
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author				Change Description            
 ** --   --------     -------				--------------------------------          
    1     
    2    01/11/2024   Devendra Shekh		added UOM changes
	3	 01/17/2025	  Moin Bloch	 Modified (Added @WorkOrderFormTypeId from WO)    
     
exec [GetSubWorkOrderChargesList] 
@subWOPartNoId=0, @IsDeleted=0,@masterCompanyId=1

**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetSubWorkOrderChargesList]  
 @subWOPartNoId bigint = null,  
 @IsDeleted bit= null,  
 @masterCompanyId int= null  
AS  
BEGIN    
  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
  SET NOCOUNT ON    
  BEGIN TRY  
			DECLARE @WorkOrderFormTypeId BIT = 0; 
			DECLARE @WorkOrderId BIGINT = 0; 

			SELECT @WorkOrderId = [WorkOrderId] FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK) WHERE [SubWOPartNoId] = @subWOPartNoId;

			SELECT @WorkOrderFormTypeId = ISNULL([WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId;
	    
            SELECT   woc.ChargesTypeId,  
                     ct.ChargeType,  
                     woc.[Description],  
                     woc.Quantity,  
                     woc.UnitCost,  
                     woc.ExtendedCost,  
                     woc.VendorId,  
                     v.VendorName,  
                     woc.CreatedBy,  
                     woc.CreatedDate,  
                     woc.IsActive,  
                     woc.IsDeleted,  
                     woc.MasterCompanyId,  
                     woc.TaskId,  
                     woc.UpdatedBy,  
                     woc.UpdatedDate,  
                     woc.SubWOPartNoId,  
                     woc.SubWorkOrderChargesId,  
                     woc.WorkOrderId,                          
					 --ISNULL(ts.Description,'') as TaskName,  
					 CASE WHEN @WorkOrderFormTypeId = 1 THEN  ISNULL(WOT.[TaskName],'')  ELSE ISNULL(ts.[Description],'') END AS TaskName,
					 woc.ReferenceNo AS ReferenceNo,  
					 ISNULL(gl.AccountName,'') AS GLAccountName,
					 woc.UOMId,  
					 um.ShortName AS 'UOM',
					 woc.IsFromWorkFlow
				 FROM [dbo].[SubWorkOrderCharges] woc WITH(NOLOCK)      
				 JOIN [dbo].[Charge] ct  WITH(NOLOCK) ON woc.ChargesTypeId = ct.ChargeId  
				 LEFT JOIN [dbo].[Vendor] v WITH(NOLOCK) ON woc.VendorId = v.VendorId       
				 LEFT JOIN [dbo].[Task] ts WITH(NOLOCK) ON woc.TaskId = ts.TaskId  
				 LEFT JOIN [dbo].[SubWorkOrderTask] WOT WITH (NOLOCK) ON WOT.SubWorkOrderTaskId = woc.TaskId
				 LEFT JOIN [dbo].[GLAccount] gl WITH(NOLOCK) ON ct.GLAccountId = gl.GLAccountId    
				 LEFT JOIN [dbo].[UnitOfMeasure] um WITH(NOLOCK) ON um.UnitOfMeasureId = woc.UOMId  
				 WHERE woc.IsDeleted = @IsDeleted AND woc.SubWOPartNoId = @subWOPartNoId AND woc.MasterCompanyId=@masterCompanyId  

  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    PRINT 'ROLLBACK'  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderChargesList'   
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWOPartNoId, '') + ''',  
                @Parameter2 = ' + ISNULL(@masterCompanyId ,'') +'''  
                @Parameter3 = ' + ISNULL(CAST(@IsDeleted AS varchar(10)) ,'') +''  
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName   = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END