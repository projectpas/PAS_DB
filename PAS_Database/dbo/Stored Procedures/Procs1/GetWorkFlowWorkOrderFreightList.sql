/*************************************************************           
 ** File:   [GetWorkFlowWorkOrderFreightList]           
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
	2    06/28/2021   Hemant Saliya  Added Tarnsation And Content Managment
	3    08/12/2024   Devendra Shekh  changed uom Description to ShortName

     
 EXECUTE [GetWorkFlowWorkOrderFreightList] 140, null,0
**************************************************************/ 
CREATE   PROCEDURE [dbo].[GetWorkFlowWorkOrderFreightList]
	-- Add the parameters for the stored procedure here	
	@wfwoId bigint = null,
	@workOrderId bigint = null,
    @IsDeleted bit= null,
	@masterCompanyId int= null
AS
BEGIN

  SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
  SET NOCOUNT ON  
  BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				Select	
					wf.Amount,
                    wf.CreatedBy,
                    wf.CreatedDate,
                    wf.IsActive,
                    wf.IsDeleted,
                    wf.MasterCompanyId,
                    wf.Memo,
                    wf.ShipViaId,
                    wf.UpdatedBy,
                    wf.UpdatedDate,
                    wf.Weight,
                    wf.WorkFlowWorkOrderId,
                    wf.WorkOrderFreightId,
                    wf.WorkOrderId,
                    sv.Name As ShipVia,
                    wf.TaskId,
                    ISNULL(ts.Description,'') as TaskName,
                    wf.Length,
                    wf.Width,
                    wf.Height,
                    wf.UOMId,
                    wf.DimensionUOMId,
                    wf.CurrencyId,
                    ISNULL(uom.ShortName,'') as UOM,
                    ISNULL(duom.ShortName,'') DimensionUOM,
                    cur.Code as Currency
				FROM dbo.WorkOrderFreight wf WITH(NOLOCK)
					JOIN dbo.ShippingVia sv WITH(NOLOCK) on wf.ShipViaId = sv.ShippingViaId
				    JOIN dbo.Task ts WITH(NOLOCK) on wf.TaskId = ts.TaskId
					LEFT JOIN dbo.UnitOfMeasure uom WITH(NOLOCK) on wf.UOMId = uom.UnitOfMeasureId
					LEFT JOIN dbo.UnitOfMeasure duom  WITH(NOLOCK) on wf.DimensionUOMId = duom.UnitOfMeasureId
					LEFT JOIN dbo.Currency cur WITH(NOLOCK) on wf.CurrencyId = cur.CurrencyId
				WHERE wf.IsDeleted = @IsDeleted AND wf.WorkFlowWorkOrderId = @wfwoId and wf.MasterCompanyId=@masterCompanyId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderQuoteVersion' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@wfwoId, '') + '''
													   @Parameter2 = '''+ ISNULL(@workOrderId, '') + '''
													   @Parameter3 = '''+ ISNULL(@MasterCompanyId, '') + '''
													   @Parameter4 = ' + ISNULL(CAST(@IsDeleted AS VARCHAR(5)) ,'') +''
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