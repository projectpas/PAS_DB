
/*************************************************************           
 ** File:   [GetWorkOrderPartWarranty]           
 ** Author: Vishal Suthar
 ** Description: This stored procedure is used retrieve Partnumber and stockline userd
 ** Purpose:         
 ** Date:   05/13/2022

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    05/13/2022   Subhash Saliya Created
     
--EXEC [GetWorkOrderPartWarranty] 16, 10048,'STL-000030'
**************************************************************/
CREATE PROCEDURE [dbo].[GetWorkOrderPartWarranty]
	@ItemMasterId bigint = 0,
	@StocklineId bigint = 0,
	@StocklineNumber varchar(100) 
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

			  declare @SerialNumber varchar(100);

			  select top 1 @SerialNumber=SerialNumber from Stockline  WITH (NOLOCK)  where StockLineId=@StocklineId AND IsParent = 1

				SELECT WO.WorkOrderNum as WorkOrderNum
				,WOBI.InvoiceNo [InvoiceNo]
				,WOPN.WorkScope as WorkScope
				,WO.Opendate as Opendate
				,WOBI.ShipDate as ShipDate
				,ST.StockLineNumber
				,IM.partnumber
				
				FROM dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK)
				INNER JOIN WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
				INNER JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WOBI.WorkOrderId AND WOPN.ID = WOBII.WorkOrderPartId
				INNER JOIN WorkOrder WO WITH (NOLOCK) ON WOBI.WorkOrderId = WO.WorkOrderId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON WOBII.ItemMasterId=IM.ItemMasterId
				INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
			    Where WOPN.ItemMasterId=@ItemMasterId and ST.isSerialized=1 and ST.SerialNumber=@SerialNumber and isnull(ST.SerialNumber,'')  != ''  AND WOBI.InvoiceStatus='Invoiced' and  WOBI.InvoiceDate > (DATEADD(year, -1, getdate())) AND WOBI.IsVersionIncrease=0

			    
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderPartWarranty' 
                     , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@ItemMasterId, '') + '''
													         @Parameter2 = ' + ISNULL(CAST(@StocklineId AS varchar(10)) ,'') +'
													         @Parameter3 = ' + ISNULL(CAST(@StocklineNumber AS varchar(10)) ,'') +''
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