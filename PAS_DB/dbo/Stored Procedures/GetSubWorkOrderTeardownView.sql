
/*************************************************************           
 ** File:   [GetSubWorkOrderTeardownView]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used retrieve Sub WorkOrderTeardown View
 ** Purpose:         
 ** Date:   03/22/2021        
          
 ** PARAMETERS:           
 @UserType varchar(60)   
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    03/22/2021   Subhash Saliya Created
	2    06/25/2020   Hemant  Saliya Added Transation & Content Management
     
--EXEC [GetSubWorkOrderTeardownView] 68
**************************************************************/

CREATE PROCEDURE [dbo].[GetSubWorkOrderTeardownView]
@subWOPartNoId  bigint=0
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
					Isshortteardown =(select top 1 isnull(Isshortteardown,0) from WorkOrderSettings WITH(NOLOCK) where WorkOrderSettingId=1)
				FROM dbo.SubWorkOrderTeardown td WITH(NOLOCK)
					JOIN  dbo.WorkOrderAdditionalComments ac WITH(NOLOCK) on td.SubWorkOrderTeardownId = ac.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderBulletinsModification bm WITH(NOLOCK) on td.SubWorkOrderTeardownId = bm.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderDiscovery  wd WITH(NOLOCK) on td.SubWorkOrderTeardownId = wd.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderFinalInspection wf WITH(NOLOCK) on td.SubWorkOrderTeardownId = wf.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderFinalTest ft WITH(NOLOCK) on td.SubWorkOrderTeardownId = ft.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderPmaDerBulletins pd WITH(NOLOCK) on td.SubWorkOrderTeardownId = pd.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderPreAssemblyInspection pa WITH(NOLOCK) on td.SubWorkOrderTeardownId = pa.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderPreAssmentResults par WITH(NOLOCK) on td.SubWorkOrderTeardownId = par.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderPreliinaryReview pr WITH(NOLOCK) on td.SubWorkOrderTeardownId = pr.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderRemovalReasons rr WITH(NOLOCK) on td.SubWorkOrderTeardownId = rr.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderTestDataUsed tdu WITH(NOLOCK) on td.SubWorkOrderTeardownId = tdu.SubWorkOrderTeardownId
					JOIN  dbo.WorkOrderWorkPerformed wp WITH(NOLOCK) on td.SubWorkOrderTeardownId = wp.SubWorkOrderTeardownId
				WHERE td.SubWOPartNoId =@subWOPartNoId
			END
		COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				ROLLBACK TRAN;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'GetSubWorkOrderTeardownView' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@subWOPartNoId, '') + ''
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