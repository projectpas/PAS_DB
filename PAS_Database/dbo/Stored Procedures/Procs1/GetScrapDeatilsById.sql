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
    1    11/14/2022   Subhash Saliya  Created
	2    16/04/2024   Moin Bloch      Added New Field Scrap Certificate Date	
     
--EXEC [GetScrapDeatilsById] 16, 10048,'STL-000030'
**************************************************************/
CREATE     PROCEDURE [dbo].[GetScrapDeatilsById]
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

			IF(ISNULL(@isSubWorkOrder,0) =0)
			BEGIN
			SELECT WO.WorkOrderNum AS WorkOrderNumber
				,WO.CustomerName CustomerName
				,ST.SerialNumber
				,CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartNumber ELSE imt.PartNumber END AS 'PartNumber'
			    ,CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartDescription ELSE imt.PartDescription END AS 'partDescription'
				,ST.Manufacturer
				,WOPN.CustomerReference
				,ISNULL(SC.ScrapCertificateId,0) AS ScrapCertificateId
				,ISNULL(SC.ScrapedByEmployeeId,0) AS ScrapedByEmployeeId
				,ISNULL(SC.ScrapedByVendorId,0) AS ScrapedByVendorId
				,ISNULL(SC.CertifiedById,0) AS CertifiedById
				,ISNULL(SC.ScrapReasonId,0) AS ScrapReasonId
				,ISNULL(SC.IsExternal,0) AS IsExternal
				,SR.Reason AS ScrapReason
				,WOPN.Id AS workOrderPartNoId
				,WO.WorkOrderId AS WorkOrderId
				,ISNULL(SC.isSubWorkOrder,0) AS isSubWorkOrder
				,SC.ScrapCertificateDate				
				FROM [dbo].[WorkOrder] WO WITH (NOLOCK)
				INNER JOIN [dbo].[WorkOrderPartNumber] WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId AND WOPN.ID = @workOrderPartNoId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON WOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
				 LEFT JOIN [dbo].[ScrapCertificate] SC WITH (NOLOCK) ON SC.WorkOrderId=WO.WorkOrderId AND WOPN.ID=SC.workOrderPartNoId
				 LEFT JOIN [dbo].[ItemMaster] imt WITH(NOLOCK) ON imt.ItemMasterId = WOPN.ItemMasterId
				 LEFT JOIN [dbo].[ScrapReason] SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
			    Where WOPN.ID=@workOrderPartNoId and WO.WorkOrderId=@workOrderId 
			END
			ELSE
			BEGIN
			SELECT WO.WorkOrderNum AS WorkOrderNumber
				,WO.CustomerName CustomerName
				,ST.SerialNumber
				,IM.partnumber
				,ST.Manufacturer
				,SWOPN.CustomerReference
				,ISNULL(SC.ScrapCertificateId,0) AS ScrapCertificateId
				,ISNULL(SC.ScrapedByEmployeeId,0) AS ScrapedByEmployeeId
				,ISNULL(SC.ScrapedByVendorId,0) AS ScrapedByVendorId
				,ISNULL(SC.CertifiedById,0) AS CertifiedById
				,ISNULL(SC.ScrapReasonId,0) AS ScrapReasonId
				,ISNULL(SC.IsExternal,0) AS IsExternal
				,SR.Reason AS ScrapReason
				,SWOPN.SubWOPartNoId AS workOrderPartNoId
				,SWO.SubWorkOrderId AS WorkOrderId
				,ISNULL(SC.isSubWorkOrder,0) AS isSubWorkOrder
				,SC.ScrapCertificateDate				
				FROM [dbo].[SubWorkOrder] SWO WITH (NOLOCK)
				INNER JOIN [dbo].[SubWorkOrderPartNumber] SWOPN WITH (NOLOCK) ON SWOPN.SubWorkOrderId =SWO.SubWorkOrderId AND SWOPN.SubWOPartNoId = @workOrderPartNoId
				INNER JOIN [dbo].[ItemMaster] IM WITH (NOLOCK) ON SWOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN [dbo].[Stockline] ST WITH (NOLOCK) ON ST.StockLineId=SWOPN.StockLineId AND ST.IsParent = 1
				 LEFT JOIN [dbo].[ScrapCertificate] SC WITH (NOLOCK) ON SC.WorkOrderId=SWOPN.SubWorkOrderId AND SWOPN.SubWOPartNoId=SC.workOrderPartNoId
				 LEFT JOIN [dbo].[ScrapReason] SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
				 LEFT JOIN [dbo].[WorkOrder] WO WITH (NOLOCK) ON WO.WorkOrderId=SWO.WorkOrderId 
			    WHERE SWOPN.SubWOPartNoId=@workOrderPartNoId AND SWO.SubWorkOrderId=@workOrderId  
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