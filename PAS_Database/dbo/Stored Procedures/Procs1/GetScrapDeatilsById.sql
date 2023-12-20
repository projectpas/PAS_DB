/*************************************************************           
 ** File:   [GetScrapDeatilsById]           
 ** Author: Subhahs Saliya
 ** Description: This stored procedure is used retrieve Scrap Certificate Data userd
 ** Purpose:         
 ** Date:   11/14/2022

 ** PARAMETERS:           
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    11/14/2022   Subhash Saliya Created
     
--EXEC [GetScrapDeatilsById] 16, 10048,'STL-000030'
**************************************************************/
Create     PROCEDURE [dbo].[GetScrapDeatilsById]
	@workOrderId bigint = 0,
	@workOrderPartNoId bigint = 0,
	@isSubWorkOrder bit = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

			IF(Isnull(@isSubWorkOrder,0) =0)
			BEGIN
			SELECT WO.WorkOrderNum as WorkOrderNumber
				,WO.CustomerName CustomerName
				,ST.SerialNumber
				,CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartNumber ELSE imt.PartNumber END as 'PartNumber'
			    ,CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartDescription ELSE imt.PartDescription END as 'partDescription'
				,ST.Manufacturer
				,WOPN.CustomerReference
				,isnull(SC.ScrapCertificateId,0) as ScrapCertificateId
				,isnull(SC.ScrapedByEmployeeId,0) as ScrapedByEmployeeId
				,isnull(SC.ScrapedByVendorId,0) as ScrapedByVendorId
				,isnull(SC.CertifiedById,0) as CertifiedById
				,isnull(SC.ScrapReasonId,0) as ScrapReasonId
				,isnull(SC.IsExternal,0) as IsExternal
				,SR.Reason as ScrapReason
				,WOPN.Id as workOrderPartNoId
				,WO.WorkOrderId as WorkOrderId
				,Isnull(SC.isSubWorkOrder,0) as isSubWorkOrder
				
				FROM dbo.WorkOrder WO WITH (NOLOCK)
				INNER JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId AND WOPN.ID = @workOrderPartNoId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
				LEFT JOIN ScrapCertificate SC WITH (NOLOCK) ON SC.WorkOrderId=WO.WorkOrderId AND WOPN.ID=SC.workOrderPartNoId
				LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = WOPN.ItemMasterId
				LEFT JOIN ScrapReason SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
			    Where WOPN.ID=@workOrderPartNoId and WO.WorkOrderId=@workOrderId 
			END
			ELSE
			BEGIN
			SELECT WO.WorkOrderNum as WorkOrderNumber
				,WO.CustomerName CustomerName
				,ST.SerialNumber
				,IM.partnumber
				,ST.Manufacturer
				,SWOPN.CustomerReference
				,isnull(SC.ScrapCertificateId,0) as ScrapCertificateId
				,isnull(SC.ScrapedByEmployeeId,0) as ScrapedByEmployeeId
				,isnull(SC.ScrapedByVendorId,0) as ScrapedByVendorId
				,isnull(SC.CertifiedById,0) as CertifiedById
				,isnull(SC.ScrapReasonId,0) as ScrapReasonId
				,isnull(SC.IsExternal,0) as IsExternal
				,SR.Reason as ScrapReason
				,SWOPN.SubWOPartNoId as workOrderPartNoId
				,SWO.SubWorkOrderId as WorkOrderId
				,Isnull(SC.isSubWorkOrder,0) as isSubWorkOrder
				
				FROM dbo.SubWorkOrder SWO WITH (NOLOCK)
				INNER JOIN SubWorkOrderPartNumber SWOPN WITH (NOLOCK) ON SWOPN.SubWorkOrderId =SWO.SubWorkOrderId AND SWOPN.SubWOPartNoId = @workOrderPartNoId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON SWOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=SWOPN.StockLineId AND ST.IsParent = 1
				LEFT JOIN ScrapCertificate SC WITH (NOLOCK) ON SC.WorkOrderId=SWOPN.SubWorkOrderId AND SWOPN.SubWOPartNoId=SC.workOrderPartNoId
				LEFT JOIN ScrapReason SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
				LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId=SWO.WorkOrderId 
			    Where SWOPN.SubWOPartNoId=@workOrderPartNoId and SWO.SubWorkOrderId=@workOrderId  
			END

				

			    
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetScrapDeatilsById' 
                     , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workOrderId, '') + '''
													         @Parameter2 = ' + ISNULL(CAST(@workOrderPartNoId AS varchar(10)) ,'') +'
													         @Parameter3 = ' + ISNULL(CAST(@isSubWorkOrder AS varchar(10)) ,'') +''
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