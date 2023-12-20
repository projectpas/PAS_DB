
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
	2    05/13/2022   Subhash Saliya Updated for Check
     
--EXEC [GetWorkOrderPartWarranty] 9, 158651,'STL-000037'
**************************************************************/
CREATE   PROCEDURE [dbo].[GetWorkOrderPartWarranty]
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

			  DECLARE @SerialNumber VARCHAR(100);

			  SELECT TOP 1 @SerialNumber=SerialNumber FROM dbo.Stockline  WITH (NOLOCK)  WHERE StockLineId = @StocklineId AND IsParent = 1

				SELECT TOP 1 WO.WorkOrderNum as WorkOrderNum
					,WOBI.InvoiceNo [InvoiceNo]
					,WOPN.WorkScope as WorkScope
					,WO.Opendate as Opendate
					,WS.ShipDate as ShipDate
					,ST.StockLineNumber
					,IM.partnumber
				FROM WorkOrderShipping WS WITH (NOLOCK)
					INNER JOIN WorkOrderShippingItem WOSI WITH (NOLOCK) ON WOSI.WorkOrderShippingId = WS.WorkOrderShippingId
					INNER JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId = WS.WorkOrderId AND WOPN.ID = WOSI.WorkOrderPartNumId
					INNER JOIN WorkOrder WO WITH (NOLOCK) ON WS.WorkOrderId = WO.WorkOrderId
					INNER JOIN ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId = IM.ItemMasterId
					INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
					LEFT JOIN  dbo.WorkOrderBillingInvoicing WOBI WITH (NOLOCK) ON WOBI.WorkOrderId = WS.WorkOrderId
					LEFT JOIN WorkOrderBillingInvoicingItem WOBII WITH (NOLOCK) ON WOBII.BillingInvoicingId =WOBI.BillingInvoicingId
			    WHERE WOPN.ItemMasterId = @ItemMasterId and ST.isSerialized = 1 and ST.SerialNumber = @SerialNumber AND ISNULL(ST.SerialNumber,'')  != ''  AND 
					WS.ShipDate > (DATEADD(year, -1, GETUTCDATE())) --WOBI.InvoiceStatus='Invoiced' AND WOBI.IsVersionIncrease=0
					ORDER BY WS.ShipDate DESC
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