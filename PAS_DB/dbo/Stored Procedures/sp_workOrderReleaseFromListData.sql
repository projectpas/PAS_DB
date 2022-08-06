/*************************************************************           
 ** File:   [sp_workOrderReleaseFromListData]           
 ** Author:   Subhash Saliya
 ** Description: Get Search Data for GetSubWOAsset List    
 ** Purpose:         
 ** Date:   23-march-2020        
          
 ** PARAMETERS:           
 @POId varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/23/2020   Subhash Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management

     
 EXECUTE [sp_workOrderReleaseFromListData] 10, 1, null, -1, '',null, '','','',null,null,null,null,null,null,0,1
**************************************************************/ 

CREATE Procedure [dbo].[sp_workOrderReleaseFromListData]
@WorkorderId bigint,
@workOrderPartNoId bigint
AS
BEGIN

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  

			    DECLARE @MSModuleId INT;
				SET @MSModuleId = 12 ; -- For WO PART NUMBER
				 SELECT 
					   wro.[ReleaseFromId]
					  ,wro.[WorkorderId]
					  ,wro.[workOrderPartNoId]
					  ,wro.[Country]
					  ,wro.[OrganizationName]
					  ,wro.[InvoiceNo]
					  ,wro.[ItemName]
					  ,UPPER(wro.[Description]) as Description
					  ,UPPER(wro.[PartNumber]) as PartNumber
					  ,wro.[Reference]
					  ,wro.[Quantity]
					  ,UPPER(wro.[Batchnumber]) as Batchnumber 
					  --,wro.[status]
					  ,wosc.conditionName as [status]
					  ,wro.[Remarks]
					  ,wro.[Certifies]
					  ,wro.[approved]
					  ,wro.[Nonapproved]
					  ,wro.[AuthorisedSign]
					  ,UPPER(case when wro.[is8130from] = 1 then le.FAALicense else le.EASALicense end) as [AuthorizationNo]
					  ,wro.[PrintedName]
					  ,wro.[Date]
					  ,wro.[AuthorisedSign2]
					  ,UPPER(case when wro.[is8130from] = 1 then le.FAALicense else le.EASALicense end) as [ApprovalCertificate]
					  ,wro.[PrintedName2]
					  ,wro.[Date2]
					  ,wro.[CFR]
					  ,wro.[Otherregulation]
					  ,wro.[MasterCompanyId]
					  ,wro.[CreatedBy]
					  ,wro.[UpdatedBy]
					  ,wro.[CreatedDate]
					  ,wro.[UpdatedDate]
					  ,wro.[IsActive]
					  ,wro.[IsDeleted]
					  ,wro.[trackingNo]
					  ,wro.[OrganizationAddress]
					  ,wro.[is8130from]
					  ,wro.[IsClosed]
					  ,wop.ReceivedDate
					  ,wop.[islocked]
					  ,wro.[IsEASALicense]
					  ,case when wro.[is8130from] = 1 then '8130 Form' else '9130 Form' end as FormType 
					  ,wop.ManagementStructureId as ManagementStructureId   
				FROM [dbo].[Work_ReleaseFrom_8130] wro WITH(NOLOCK)
				      LEFT JOIN dbo.WorkOrderPartNumber wop WITH(NOLOCK) on wro.workOrderPartNoId = wop.Id
					  LEFT JOIN dbo.WorkOrderSettlementDetails wosc WITH(NOLOCK) on wop.WorkOrderId = wosc.WorkOrderId AND wop.ID = wosc.workOrderPartNoId AND wosc.WorkOrderSettlementId = 9
				      LEFT JOIN DBO.WorkOrderManagementStructureDetails MSD  WITH(NOLOCK) on MSD.ModuleID = @MSModuleId AND MSD.ReferenceID = wop.Id
					  LEFT JOIN DBO.ManagementStructurelevel MSL WITH(NOLOCK) ON MSL.ID = MSD.Level1Id
					  LEFT JOIN DBO.LegalEntity  le  WITH(NOLOCK) on le.LegalEntityId   = MSL.LegalEntityId 
				WHERE wro.WorkOrderId=@WorkorderId AND wro.workOrderPartNoId =@workOrderPartNoId  
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'sp_workOrderReleaseFromListData' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkorderId, '') + '''
													   @Parameter18 = ' + ISNULL(CAST(@workOrderPartNoId AS varchar(10)) ,'') +''
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