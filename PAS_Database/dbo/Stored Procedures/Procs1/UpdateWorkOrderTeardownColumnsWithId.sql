
/*************************************************************           
 ** File:   [UpdateWorkOrderTeardownColumnsWithId]           
 ** Author:   Subhash Saliya
 ** Description: This stored procedure is used Update WorkOrderTeardownColumnsWithId 
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
    2    03/01/2021   Subhash Saliya Changes Lower data
	3    06/25/2021   Hemant Saliya  Added SQL Standards & Content Managment
     
--EXEC [UpdateWorkOrderTeardownColumnsWithId] 5
**************************************************************/

CREATE PROCEDURE [dbo].[UpdateWorkOrderTeardownColumnsWithId]
    @TableName varchar(100),
	@TableprimaryId bigint
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN
				if(LOWER(@TableName) ='workorderadditionalcomments')
				 BEGIN
						 Update WoD SET 
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].[WorkOrderAdditionalComments] WoD WITH(NOLOCK)
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderAdditionalCommentsId = @TableprimaryId
				 END
				 Else if(LOWER(@TableName) ='workorderbulletinsmodification')
				 BEGIN
						 Update WoD SET 
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderBulletinsModification WoD WITH(NOLOCK)
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderBulletinsModificationId = @TableprimaryId
				 END
				 else if(LOWER(@TableName) ='workorderdiscovery')
				 BEGIN
	      				 Update WoD SET 
						 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						 WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].[WorkOrderDiscovery] WoD WITH(NOLOCK)
						 INNER JOIN dbo.Employee E WITH(NOLOCK) ON WoD.InspectorId = E.EmployeeId
						 INNER JOIN dbo.Employee E1 WITH(NOLOCK) ON WoD.TechnicianId = E1.EmployeeId
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderDiscoveryId = @TableprimaryId
				 END
				 else if(LOWER(@TableName) ='workorderfinalinspection')
				 BEGIN
	      				 Update WoD SET 
						 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].[WorkOrderFinalInspection] WoD WITH(NOLOCK)
						 INNER JOIN dbo.Employee E WITH(NOLOCK) ON WoD.InspectorId = E.EmployeeId
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderFinalInspectionId = @TableprimaryId
				 END
				 else if(LOWER(@TableName) ='workorderfinaltest')
				 BEGIN
	      				 Update WoD SET 
						 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						 WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].[WorkOrderFinalTest] WoD WITH(NOLOCK)
						 INNER JOIN dbo.Employee E WITH(NOLOCK) ON WoD.InspectorId = E.EmployeeId
						 INNER JOIN dbo.Employee E1 WITH(NOLOCK) ON WoD.TechnicianId = E1.EmployeeId
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderFinalTestId = @TableprimaryId
			
				 END
				 Else if(LOWER(@TableName) ='workorderpmaderbulletins')
				 BEGIN
						 Update WoD SET 
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderPmaDerBulletins WoD WITH(NOLOCK)
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderPmaDerBulletinsId = @TableprimaryId
				 END
				 else if(LOWER(@TableName) ='workorderpreassemblyinspection')
				 BEGIN
	      				 Update WoD SET 
						 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						 WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderPreAssemblyInspection WoD WITH(NOLOCK)
						 INNER JOIN dbo.Employee E WITH(NOLOCK) ON WoD.InspectorId = E.EmployeeId
						 INNER JOIN dbo.Employee E1 WITH(NOLOCK) ON WoD.TechnicianId = E1.EmployeeId
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderPreAssemblyInspectionId = @TableprimaryId
				 END
				 else if(LOWER(@TableName) ='workorderpreassmentresults')
				 BEGIN
	      				 Update WoD SET 
						 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						 WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderPreAssmentResults WoD WITH(NOLOCK)
						 INNER JOIN dbo.Employee E WITH(NOLOCK) ON WoD.InspectorId = E.EmployeeId
						 INNER JOIN dbo.Employee E1 WITH(NOLOCK) ON WoD.TechnicianId = E1.EmployeeId
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderPreAssmentResultsId = @TableprimaryId
				 END
				  else if(LOWER(@TableName) ='workorderpreliinaryreview')
				 BEGIN
	      				 Update WoD SET 
						 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderPreliinaryReview WoD WITH(NOLOCK)
						 INNER JOIN dbo.Employee E WITH(NOLOCK) ON WoD.InspectorId = E.EmployeeId
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderPreliinaryReviewId = @TableprimaryId
				 END
				 Else if(LOWER(@TableName) ='workorderremovalreasons')
				 BEGIN
						 Update WoD SET 
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderRemovalReasons WoD WITH(NOLOCK)
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderRemovalReasonsId = @TableprimaryId
				 END
				 Else if(LOWER(@TableName) ='workordertestdataused')
				 BEGIN
						 Update WoD SET 
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderTestDataUsed WoD WITH(NOLOCK)
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderTestDataUsedId = @TableprimaryId
				 END
				 else if(LOWER(@TableName) ='workorderworkperformed')
				 BEGIN
	      				 Update WoD SET 
						 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						 WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
						 WoD.ReasonName = wdr.Reason
						 FROM [dbo].WorkOrderWorkPerformed WoD WITH(NOLOCK)
						 INNER JOIN dbo.Employee E WITH(NOLOCK) ON WoD.InspectorId = E.EmployeeId
						 INNER JOIN dbo.Employee E1 WITH(NOLOCK) ON WoD.TechnicianId = E1.EmployeeId
						 INNER JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON WoD.ReasonId = wdr.TeardownReasonId
						 Where WoD.WorkOrderWorkPerformedId = @TableprimaryId
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
              , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderTeardownColumnsWithId' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@TableName, '') + ''',													   
													   @Parameter2 = ' + ISNULL(CAST(@TableprimaryId AS varchar(10)) ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN
		END CATCH
END