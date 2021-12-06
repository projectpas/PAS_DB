
/*************************************************************           
 ** File:   [GetWorkOrderTeardownView]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used retrieve WorkOrderTeardown View
 ** Purpose:         
 ** Date:   02/26/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    02/26/2021   Subhash Saliya Created
	2	 06/28/2021	  Hemant Saliya  Added Transation & Content Managment
     
--EXEC [GetWorkOrderTeardownView] 33
**************************************************************/

CREATE PROCEDURE [dbo].[GetWorkOrderTeardownView]
@wowfId  bigint = 0
AS
BEGIN
	

	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
			   SELECT TOP 1     
					ISNULL(wd.ReasonName,'') DiscoveryReason,
                    ISNULL(wd.TechnicalName,'') as DiscoveryTechnician,
                    ISNULL(wd.InspectorName,'') as DiscoveryInspector,
                    ISNULL(wf.InspectorName,'') as FinalInspectionInspector,
                    ISNULL(wf.ReasonName,'') as FinalInspectionReason,
                    ISNULL(ft.TechnicalName,'') as FinalTestTechnician,
                    ISNULL(ft.InspectorName,'') as FinalTestInspector,
                    ISNULL(ft.ReasonName,'') as FinalTestReason,
                    ISNULL(pa.TechnicalName,'') as AssemblyInspectionTechnician,
                    ISNULL(pa.InspectorName,'') as  AssemblyInspectionInspector,
                    ISNULL(pa.ReasonName,'') as AssemblyInspectionReason,
                    ISNULL(par.TechnicalName,'') as  AssmentResultsTechnician,
                    ISNULL(par.InspectorName,'') as  AssmentResultsInspector,
                    ISNULL(par.ReasonName,'') as AssmentResultsReason,
                    ISNULL(pr.InspectorName,'') as  PreliinaryReviewInspector,
                    ISNULL(pr.ReasonName,'')  as PreliinaryReviewReason,
                    ISNULL(wp.TechnicalName,'') as WorkPerformedTechnician,
                    ISNULL(wp.InspectorName,'') as WorkPerformedInspector,
                    ISNULL(wp.ReasonName,'') as WorkPerformedReason,
                    ISNULL(ac.Memo,'') as AdditionalCommentsMemo,
                    ISNULL(ac.ReasonName,'') as AdditionalCommentsReason,
                    ISNULL(bm.Memo,'') BulletinsModificationMemo,
                    ISNULL(bm.ReasonName,'') as BulletinsModificationReason,
                    ISNULL(pd.ReasonName,'') as PMADerReason,
                    ISNULL(rr.ReasonName,'') as RemovalReason,
                    ISNULL(tdu.ReasonName,'') as DatausedReason,
                    ISNULL(wd.Memo,'') as DiscoveryMemo,
                    wd.TechnicianDate as DiscoveryTechnicianDate,
                    wd.InspectorDate DiscoveryInspectorDate,
                    wf.Memo FinalInspectionMemo,
                    wf.InspectorDate FinalInspectionInspectorDate,
                    ft.Memo FinalTestMemo,
                    ft.InspectorDate FinalTestInspectorDate,
                    ft.TechnicianDate FinalTestTechnicianDate,
                    pd.DERRepairs,
                    pd.MandatoryService,
                    pd.PMAParts,
                    pd.RequestedService,
                    pd.ServiceLetters,
					pd.AirworthinessDirecetives,
                    par.Memo AssmentResultsMemo,
                    par.TechnicianDate AssmentResultsTechnicianDate,
                    par.InspectorDate AssmentResultsInspectorDate,
                    pr.Memo PreliinaryReviewMemo,
                    pr.InspectorDate PreliinaryReviewInspectorDate,
                    rr.Memo RemovalReasonsMemo,
                    tdu.Memo DataUsedMemo,
                    wp.Memo WorkPerformedMemo,
                    wp.TechnicianDate WorkPerformedTechnicianDate,
                    wp.InspectorDate WorkPerformedInspectorDate,
                    pa.Memo AssemblyInspectionMemo,
                    pa.TechnicianDate AssemblyInspectionTechnicianDate,
                    pa.InspectorDate AssemblyInspectionInspectorDate,
                    td.IsAdditionalComments,
                    td.IsBulletinsModification,
                    td.IsDiscovery,
                    td.IsFinalInspection,
                    td.IsFinalTest,
                    td.IsPmaDerBulletins,
                    td.IsPreAssemblyInspection,
                    td.IsPreAssmentResults,
                    td.IsPreliinaryReview,
                    td.IsRemovalReasons,
                    td.IsTestDataUsed,
                    td.IsWorkPerformed,
					Isshortteardown =(SELECT TOP 1 isnull(Isshortteardown,0) FROM WorkOrderSettings WITH(NOLOCK) WHERE WorkOrderSettingId=1)
				FROM dbo.WorkOrderTeardown td WITH(NOLOCK)
					join  dbo.WorkOrderAdditionalComments ac WITH(NOLOCK) on td.WorkOrderTeardownId = ac.WorkOrderTeardownId
					join  dbo.WorkOrderBulletinsModification bm WITH(NOLOCK) on td.WorkOrderTeardownId = bm.WorkOrderTeardownId
					join  dbo.WorkOrderDiscovery  wd WITH(NOLOCK) on td.WorkOrderTeardownId = wd.WorkOrderTeardownId
					join  dbo.WorkOrderFinalInspection wf WITH(NOLOCK) on td.WorkOrderTeardownId = wf.WorkOrderTeardownId
					join  dbo.WorkOrderFinalTest ft WITH(NOLOCK) on td.WorkOrderTeardownId = ft.WorkOrderTeardownId
					join  dbo.WorkOrderPmaDerBulletins pd WITH(NOLOCK) on td.WorkOrderTeardownId = pd.WorkOrderTeardownId
					join  dbo.WorkOrderPreAssemblyInspection pa WITH(NOLOCK) on td.WorkOrderTeardownId = pa.WorkOrderTeardownId
					join  dbo.WorkOrderPreAssmentResults par WITH(NOLOCK) on td.WorkOrderTeardownId = par.WorkOrderTeardownId
					join  dbo.WorkOrderPreliinaryReview pr WITH(NOLOCK) on td.WorkOrderTeardownId = pr.WorkOrderTeardownId
					join  dbo.WorkOrderRemovalReasons rr WITH(NOLOCK) on td.WorkOrderTeardownId = rr.WorkOrderTeardownId
					join  dbo.WorkOrderTestDataUsed tdu WITH(NOLOCK) on td.WorkOrderTeardownId = tdu.WorkOrderTeardownId
					join  dbo.WorkOrderWorkPerformed wp WITH(NOLOCK) on td.WorkOrderTeardownId = wp.WorkOrderTeardownId
				WHERE td.WorkFlowWorkOrderId =@wowfId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetWorkOrderTeardownView' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@wowfId, '') + ''
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