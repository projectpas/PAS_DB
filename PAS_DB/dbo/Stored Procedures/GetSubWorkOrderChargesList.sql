﻿/*************************************************************           
 ** File:   [GetSubWorkOrderChargesList]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for Work order Chagres List    
 ** Purpose:         
 ** Date:   22-Feb-2021        
          
 ** PARAMETERS:           
 @POId varchar(60)   
 ** RETURN VALUE:           
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/22/2021   Subhash Saliya Created
     
 EXECUTE [GetWorkFlowWorkOrderChargesList] 148, null, 0
**************************************************************/ 

CREATE PROCEDURE [dbo].[GetSubWorkOrderChargesList]
	@subWOPartNoId bigint = null,
    @IsDeleted bit= null,
	@masterCompanyId int= null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
	BEGIN TRY
			BEGIN TRANSACTION
				BEGIN  
					SELECT	
					     woc.ChargesTypeId,
                         ct.ChargeType as ChargeType,
                         woc.Description,
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
						ISNULL(ts.Description,'') as TaskName,
						woc.ReferenceNo as ReferenceNo,
						ISNULL(gl.AccountName,'') as GLAccountName
					FROM dbo.SubWorkOrderCharges woc WITH(NOLOCK)				
					JOIN dbo.Charge ct  WITH(NOLOCK) on woc.ChargesTypeId = ct.ChargeId
					LEFT JOIN dbo.Vendor v WITH(NOLOCK) on woc.VendorId = v.VendorId
					JOIN dbo.Task ts WITH(NOLOCK) on woc.TaskId = ts.TaskId
					JOIN dbo.GLAccount gl WITH(NOLOCK) on ct.GLAccountId = gl.GLAccountId				
					WHERE woc.IsDeleted = @IsDeleted AND woc.SubWOPartNoId = @subWOPartNoId and woc.MasterCompanyId=@masterCompanyId
				END
			COMMIT  TRANSACTION
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderChargesList' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWOPartNoId, '') + ''',
													   @Parameter2 = ' + ISNULL(@masterCompanyId ,'') +'''
													   @Parameter3 = ' + ISNULL(CAST(@IsDeleted AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END