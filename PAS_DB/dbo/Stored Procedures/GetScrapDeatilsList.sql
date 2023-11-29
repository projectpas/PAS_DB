﻿/*************************************************************           
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
     
--EXEC [GetScrapDeatilsList] 16, 10048,'STL-000030'
**************************************************************/
CREATE       PROCEDURE [dbo].[GetScrapDeatilsList]
	@workOrderId bigint = 0,
	@workOrderPartNoId bigint = 0,
	@IsSubWorkOrder bit = 0
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

			IF(Isnull(@isSubWorkOrder,0) =0)
			BEGIN
			SELECT UPPER(WO.WorkOrderNum) as WorkOrderNumber
				,UPPER(WO.CustomerName) CustomerName
				,ST.SerialNumber
				,UPPER(CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartNumber ELSE imt.PartNumber END) as 'PartNumber'
			    ,UPPER(CASE WHEN ISNULL(WOPN.RevisedItemmasterid, 0) > 0 THEN WOPN.RevisedPartDescription ELSE imt.PartDescription END) as 'partDescription'
				,UPPER(ST.Manufacturer) AS Manufacturer
				,UPPER(ST.ControlNumber) as cntrlNum
				,UPPER(WOPN.CustomerReference) AS CustomerReference
				,isnull(SC.ScrapCertificateId,0) as ScrapCertificateId
				,isnull(SC.ScrapedByEmployeeId,0) as ScrapedByEmployeeId
				,isnull(SC.ScrapedByVendorId,0) as ScrapedByVendorId
				,isnull(SC.CertifiedById,0) as CertifiedById
				,isnull(SC.ScrapReasonId,0) as ScrapReasonId
				,isnull(SC.IsExternal,0) as IsExternal
				,UPPER(case when isnull(SC.IsExternal,0)  =1 then vo.vendorName else (EM.FirstName +'  '+EM.LastName) end) as ScrapedByEmployee 
				,UPPER(SR.Reason) as ScrapReason
				,WOPN.Id as workOrderPartNoId
				,WO.WorkOrderId as WorkOrderId
				,UPPER(EMc.FirstName +'  '+EMc.LastName) as CertifiedBy
				,isnull(SC.CreatedBy,WO.CreatedBy) as CreatedBy
				,isnull(SC.UpdatedBy,WO.UpdatedBy) as UpdatedBy
				,isnull(SC.CreatedDate,WO.CreatedDate) as CreatedDate
				,isnull(SC.UpdatedDate,WO.UpdatedDate) as UpdatedDate
				,Isnull(SC.isSubWorkOrder,0) as isSubWorkOrder
				,WOPN.ManagementStructureId
				,WOPN.MasterCompanyId
				FROM dbo.WorkOrder WO WITH (NOLOCK)
				INNER JOIN WorkOrderPartNumber WOPN WITH (NOLOCK) ON WOPN.WorkOrderId =WO.WorkOrderId AND WOPN.ID = @workOrderPartNoId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON WOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=WOPN.StockLineId AND ST.IsParent = 1
				LEFT JOIN ScrapCertificate SC WITH (NOLOCK) ON SC.WorkOrderId=WO.WorkOrderId AND WOPN.ID=SC.workOrderPartNoId
				LEFT JOIN DBO.ItemMaster imt WITH(NOLOCK) on imt.ItemMasterId = WOPN.ItemMasterId
				LEFT JOIN ScrapReason SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
				LEFT JOIN vendor vo WITH (NOLOCK) ON vo.vendorid=SC.ScrapedByVendorId 
				LEFT JOIN employee EM WITH (NOLOCK) ON EM.EmployeeId=SC.ScrapedByEmployeeId 
				LEFT JOIN employee EMc WITH (NOLOCK) ON EMc.EmployeeId=SC.CertifiedById 
			    Where WOPN.ID=@workOrderPartNoId and WO.WorkOrderId=@workOrderId 
			END
			BEGIN

			  DECLARE @ManagementStructureId INT;
					

					SELECT top 1 @ManagementStructureId = WS.ManagementStructureId FROM DBO.SubWorkOrderPartNumber sWS WITH (NOLOCK) inner join WorkOrderPartNumber ws on sws.WorkOrderId=ws.WorkOrderId  where SubWOPartNoId= @workOrderPartNoId  
			   SELECT UPPER(WO.WorkOrderNum) as WorkOrderNumber
				,UPPER(WO.CustomerName) CustomerName
				,ST.SerialNumber
				,UPPER(IM.partnumber) AS partnumber 
				,UPPER(ST.Manufacturer) AS Manufacturer
				,UPPER(SWOPN.CustomerReference) AS CustomerReference
				,isnull(SC.ScrapCertificateId,0) as ScrapCertificateId
				,isnull(SC.ScrapedByEmployeeId,0) as ScrapedByEmployeeId
				,isnull(SC.ScrapedByVendorId,0) as ScrapedByVendorId
				,isnull(SC.CertifiedById,0) as CertifiedById
				,isnull(SC.ScrapReasonId,0) as ScrapReasonId
				,isnull(SC.IsExternal,0) as IsExternal
				,UPPER(case when isnull(SC.IsExternal,0)  =1 then vo.vendorName else (EM.FirstName +'  '+EM.LastName) end) as ScrapedByEmployee 
				,UPPER(SR.Reason) as ScrapReason
				,SWOPN.SubWOPartNoId as workOrderPartNoId
				,SWO.SubWorkOrderId as WorkOrderId
				,UPPER(EMc.FirstName +'  '+EMc.LastName) as CertifiedBy
				,isnull(SC.CreatedBy,SWO.CreatedBy) as CreatedBy
				,isnull(SC.UpdatedBy,SWO.UpdatedBy) as UpdatedBy
				,isnull(SC.CreatedDate,SWO.CreatedDate) as CreatedDate
				,isnull(SC.UpdatedDate,SWO.UpdatedDate) as UpdatedDate
				,Isnull(SC.isSubWorkOrder,0) as isSubWorkOrder
				,@ManagementStructureId as ManagementStructureId
				,SWO.MasterCompanyId
				FROM dbo.SubWorkOrder SWO WITH (NOLOCK)
				INNER JOIN SubWorkOrderPartNumber SWOPN WITH (NOLOCK) ON SWOPN.SubWorkOrderId =SWO.SubWorkOrderId AND SWOPN.SubWOPartNoId = @workOrderPartNoId
				INNER JOIN ItemMaster IM WITH (NOLOCK) ON SWOPN.ItemMasterId=IM.ItemMasterId
				INNER JOIN Stockline ST WITH (NOLOCK) ON ST.StockLineId=SWOPN.StockLineId AND ST.IsParent = 1
				LEFT JOIN ScrapCertificate SC WITH (NOLOCK) ON SC.WorkOrderId=SWOPN.SubWorkOrderId AND SWOPN.SubWOPartNoId=SC.workOrderPartNoId
				LEFT JOIN ScrapReason SR WITH (NOLOCK) ON SR.Id=SC.ScrapReasonId 
				LEFT JOIN WorkOrder WO WITH (NOLOCK) ON WO.WorkOrderId=SWO.WorkOrderId 
				LEFT JOIN vendor vo WITH (NOLOCK) ON vo.vendorid=SC.ScrapedByVendorId 
				LEFT JOIN employee EM WITH (NOLOCK) ON EM.EmployeeId=SC.ScrapedByEmployeeId 
				LEFT JOIN employee EMc WITH (NOLOCK) ON EMc.EmployeeId=SC.CertifiedById 
			    Where SWOPN.SubWOPartNoId=@workOrderPartNoId and SWO.SubWorkOrderId=@workOrderId and SC.isSubWorkOrder= 1 
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
													         @Parameter3 = ' + ISNULL(CAST(@IsSubWorkOrder AS varchar(10)) ,'') +''
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