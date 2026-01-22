
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

create PROCEDURE [dbo].[InserUpdateSubWorkOrderTeardown]
    @TableName varchar(100) ='',
	@TableprimaryId bigint = 0,
	@WorkOrderTeardownId  bigint= 0,
	@WorkOrderId bigint= 0,
	@WorkFlowWorkOrderId bigint= 0,
	@ischeckvalue bit = 0,
	@SubWorkOrderTeardownId bigint= null,
	@Memo varchar(max) =null,
	@ReasonId bigint= null,
	@IsDocument bit = 0,
	@MasterCompanyId bigint= 0,
	@CreatedBy varchar(200)= null,
	@UpdatedBy varchar(200)= null,
	@CreatedDate datetime,
	@UpdatedDate datetime,
	@IsActive bit,
	@IsDeleted bit,
	@airworthinessDirecetives varchar(200)= null,
	@mandatoryService varchar(200)= null,
	@requestedService varchar(200)= null,
	@serviceLetters varchar(200)= null,
	@pmaParts varchar(200)= null,
	@derRepairs varchar(200)= null,
	@technicianId bigint= null,
	@technicianDate datetime= null,
	@inspectorId bigint = null,
	@inspectorDate datetime = null,
	@SubWorkOrderId bigint = 0,
	@SubWOPartNoId bigint = 0
AS
BEGIN
	 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
     SET NOCOUNT ON

	 BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

			    if(@SubWorkOrderTeardownId = 0)
				 begin 
				        insert into SubWorkOrderTeardown(
									WorkOrderId,
									SubWOPartNoId,
									SubWorkOrderId,
									MasterCompanyId,
									CreatedBy,
									UpdatedBy,
									CreatedDate,
									UpdatedDate,
									IsActive,
									IsDeleted,
									IsAdditionalComments,
									IsBulletinsModification,
									IsDiscovery,
									IsFinalInspection,
									IsFinalTest,
									IsPmaDerBulletins,
									IsPreAssemblyInspection,
									IsPreAssmentResults,
									IsPreliinaryReview,
									IsRemovalReasons,
									IsTestDataUsed
									)

									values(@WorkOrderId,
									@SubWOPartNoId,
									@SubWorkOrderId,
									@MasterCompanyId,
									@CreatedBy,
									@UpdatedBy,
									@CreatedDate,
									@UpdatedDate,
									@IsActive,
									@IsDeleted,
									0,
									0,
									0,
									0,
									0,
									0,
									0,
									0,
									0,
									0,
									0)

				        SELECT @SubWorkOrderTeardownId = SCOPE_IDENTITY()

						insert into  [dbo].[WorkOrderAdditionalComments] (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)

						insert into  [dbo].WorkOrderBulletinsModification (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)


						insert into  [dbo].WorkOrderDiscovery (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)

						insert into  [dbo].[WorkOrderFinalInspection] (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)

				
						insert into  [dbo].[WorkOrderFinalTest] (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)

						insert into  [dbo].WorkOrderPmaDerBulletins (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)


						insert into  [dbo].WorkOrderPreAssemblyInspection (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)

						insert into  [dbo].WorkOrderPreAssmentResults (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																  values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)


						insert into  [dbo].WorkOrderPreliinaryReview (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																   values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)


						insert into  [dbo].WorkOrderRemovalReasons (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																   values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)

						insert into  [dbo].WorkOrderTestDataUsed (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																   values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)

						insert into  [dbo].WorkOrderWorkPerformed (WorkOrderTeardownId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,SubWorkOrderTeardownId)
																   values (null,@MasterCompanyId,@CreatedBy,@UpdatedBy,@CreatedDate,@UpdatedDate,1,0,@SubWorkOrderTeardownId)


				 end

				if(@WorkOrderTeardownId =0)
				  begin
				       set @WorkOrderTeardownId= null
				  end
				if(@ReasonId =0)
				  begin
				     set @ReasonId= null
				  end
                if(@technicianId =0)
				  begin
				       set @technicianId= null
				  end
				if(@inspectorId =0)
				  begin
				     set @inspectorId= null
				  end

				if(LOWER(@TableName) ='workorderadditionalcomments')
				 BEGIN

							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsAdditionalComments=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end

							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderAdditionalCommentsId  from [WorkOrderAdditionalComments] where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end

							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
										 WoD.ReasonName = wdr.Reason,
										 wod.Memo=@memo,
										 WoD.ReasonId = @ReasonId,
										 wod.UpdatedBy=@UpdatedBy,
										 wod.UpdatedDate=@UpdatedDate,
										 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
								  FROM [dbo].[WorkOrderAdditionalComments] WoD WITH(NOLOCK)
									     left JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
									     Where WoD.WorkOrderAdditionalCommentsId = @TableprimaryId
							 end
				 END
				 Else if(LOWER(@TableName) ='workorderbulletinsmodification')
				 BEGIN   

							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsBulletinsModification=@ischeckvalue where SubWorkOrderTeardownId = SubWorkOrderTeardownId
							 end

							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderBulletinsModificationId  from WorkOrderBulletinsModification where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end

							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
										 WoD.ReasonName = wdr.Reason,
										 wod.Memo=@memo,
										 WoD.ReasonId = @ReasonId,
										 wod.UpdatedBy=@UpdatedBy,
										 wod.UpdatedDate=@UpdatedDate,
										 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
								  FROM [dbo].WorkOrderBulletinsModification WoD WITH(NOLOCK)
									     left JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
									     Where WoD.WorkOrderBulletinsModificationId = @TableprimaryId
							 end
				 END
				 else if(LOWER(@TableName) ='workorderdiscovery')
				 BEGIN
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsDiscovery=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderDiscoveryId  from [WorkOrderDiscovery] where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.Memo=@memo,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						             WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
									 wod.InspectorId=@inspectorId,
							 		 wod.TechnicianId=@technicianId,
									 wod.InspectorDate=@inspectorDate,
							 		 wod.TechnicianDate=@technicianDate,
									 wod.IsDocument=@IsDocument,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].[WorkOrderDiscovery] WoD WITH(NOLOCK)
							         LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
						             LEFT JOIN dbo.Employee E1 WITH(NOLOCK) ON @technicianId = E1.EmployeeId
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderDiscoveryId = @TableprimaryId
							 end
				 END
				 else if(LOWER(@TableName) ='workorderfinalinspection')
				 BEGIN
							 
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsFinalInspection=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderFinalInspectionId  from [WorkOrderFinalInspection] where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.Memo=@memo,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
									 wod.InspectorId=@inspectorId,
									 wod.InspectorDate=@inspectorDate,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].[WorkOrderFinalInspection] WoD WITH(NOLOCK)
							         LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderFinalInspectionId = @TableprimaryId
							 end
				 END
				 else if(LOWER(@TableName) ='workorderfinaltest')
				 BEGIN
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsFinalTest=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderFinalTestId  from [WorkOrderFinalTest] where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.Memo=@memo,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						             WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
									 wod.InspectorId=@inspectorId,
							 		 wod.TechnicianId=@technicianId,
									 wod.InspectorDate=@inspectorDate,
							 		 wod.TechnicianDate=@technicianDate,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].[WorkOrderFinalTest] WoD WITH(NOLOCK)
							         LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
						             LEFT JOIN dbo.Employee E1 WITH(NOLOCK) ON @technicianId = E1.EmployeeId
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderFinalTestId = @TableprimaryId
							 end
			
				 END
				 Else if(LOWER(@TableName) ='workorderpmaderbulletins')
				 BEGIN
							 
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsPmaDerBulletins=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderPmaDerBulletinsId  from WorkOrderPmaDerBulletins where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.AirworthinessDirecetives=@airworthinessDirecetives,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.MandatoryService = @mandatoryService,
						             WoD.RequestedService = @requestedService,
									 wod.ServiceLetters=@serviceLetters,
							 		 wod.PMAParts=@pmaParts,
									 wod.DERRepairs=@derRepairs,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].WorkOrderPmaDerBulletins WoD WITH(NOLOCK)
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderPmaDerBulletinsId = @TableprimaryId
							 end
				 END
				 else if(LOWER(@TableName) ='workorderpreassemblyinspection')
				 BEGIN
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsPreAssemblyInspection=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderPreAssemblyInspectionId  from WorkOrderPreAssemblyInspection where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.Memo=@memo,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						             WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
									 wod.InspectorId=@inspectorId,
							 		 wod.TechnicianId=@technicianId,
									 wod.InspectorDate=@inspectorDate,
							 		 wod.TechnicianDate=@technicianDate,
									 wod.IsDocument=@IsDocument,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].WorkOrderPreAssemblyInspection WoD WITH(NOLOCK)
							         LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
						             LEFT JOIN dbo.Employee E1 WITH(NOLOCK) ON @technicianId = E1.EmployeeId
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderPreAssemblyInspectionId = @TableprimaryId
						    end
				 END
				 else if(LOWER(@TableName) ='workorderpreassmentresults')
				 BEGIN
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsPreAssmentResults=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderPreAssmentResultsId  from WorkOrderPreAssmentResults where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.Memo=@memo,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						             WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
									 wod.InspectorId=@inspectorId,
							 		 wod.TechnicianId=@technicianId,
									 wod.InspectorDate=@inspectorDate,
							 		 wod.TechnicianDate=@technicianDate,
									 wod.IsDocument=@IsDocument,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].WorkOrderPreAssmentResults WoD WITH(NOLOCK)
							         LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
						             LEFT JOIN dbo.Employee E1 WITH(NOLOCK) ON @technicianId = E1.EmployeeId
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderPreAssmentResultsId = @TableprimaryId
						    end
				 END
				  else if(LOWER(@TableName) ='workorderpreliinaryreview')
				 BEGIN
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsPreliinaryReview=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderPreliinaryReviewId  from WorkOrderPreliinaryReview where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.Memo=@memo,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
									 wod.InspectorId=@inspectorId,
									 wod.InspectorDate=@inspectorDate,
									 wod.IsDocument=@IsDocument,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].WorkOrderPreliinaryReview WoD WITH(NOLOCK)
							         LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderPreliinaryReviewId = @TableprimaryId
							 end
				 END
				 Else if(LOWER(@TableName) ='workorderremovalreasons')
				 BEGIN
						 if(isnull(@SubWorkOrderTeardownId,0) > 0)
						 begin 
						  update SubWorkOrderTeardown set IsRemovalReasons=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
						 end

						 if(isnull(@TableprimaryId,0) = 0)
						 begin
						  select @TableprimaryId =WorkOrderRemovalReasonsId  from WorkOrderRemovalReasons where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
						 end


						 if(isnull(@TableprimaryId,0) > 0)
						 begin 

						  Update WoD SET 
								 WoD.ReasonName = wdr.Reason,
								 wod.Memo=@memo,
								 WoD.ReasonId = @ReasonId,
								 wod.UpdatedBy=@UpdatedBy,
								 wod.UpdatedDate=@UpdatedDate,
								 wod.IsDocument=@IsDocument,
								 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
					    FROM [dbo].WorkOrderRemovalReasons WoD WITH(NOLOCK)
								 LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
								 Where WoD.WorkOrderRemovalReasonsId = @TableprimaryId
						end


				 END
				 Else if(LOWER(@TableName) ='workordertestdataused')
				 BEGIN
						 if(isnull(@SubWorkOrderTeardownId,0) > 0)
						 begin 
						  update SubWorkOrderTeardown set IsTestDataUsed=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
						 end

						 if(isnull(@TableprimaryId,0) = 0)
						 begin
						  select @TableprimaryId =WorkOrderTestDataUsedId  from WorkOrderTestDataUsed where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
						 end


						 if(isnull(@TableprimaryId,0) > 0)
						 begin 

						  Update WoD SET 
								 WoD.ReasonName = wdr.Reason,
								 wod.Memo=@memo,
								 WoD.ReasonId = @ReasonId,
								 wod.UpdatedBy=@UpdatedBy,
								 wod.UpdatedDate=@UpdatedDate,
								 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
					    FROM [dbo].WorkOrderTestDataUsed WoD WITH(NOLOCK)
								 LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
								 Where WoD.WorkOrderTestDataUsedId = @TableprimaryId
						end
				 END
				 else if(LOWER(@TableName) ='workorderworkperformed')
				 BEGIN
							 if(isnull(@SubWorkOrderTeardownId,0) > 0)
							 begin 
							      update SubWorkOrderTeardown set IsWorkPerformed=@ischeckvalue where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) = 0)
							 begin
							      select @TableprimaryId =WorkOrderWorkPerformedId  from WorkOrderWorkPerformed where SubWorkOrderTeardownId = @SubWorkOrderTeardownId
							 end
							 
							 if(isnull(@TableprimaryId,0) > 0)
							 begin 
							      Update WoD SET 
							 		 WoD.ReasonName = wdr.Reason,
							 		 wod.Memo=@memo,
							 		 WoD.ReasonId = @ReasonId,
							 		 wod.UpdatedBy=@UpdatedBy,
							 		 wod.UpdatedDate=@UpdatedDate,
									 WoD.InspectorName = E.FirstName + ' ' + E.LastName,
						             WoD.TechnicalName = E1.FirstName + ' ' + E1.LastName,
									 wod.InspectorId=@inspectorId,
							 		 wod.TechnicianId=@technicianId,
									 wod.InspectorDate=@inspectorDate,
							 		 wod.TechnicianDate=@technicianDate,
							 		 wod.SubWorkOrderTeardownId=@SubWorkOrderTeardownId
							   FROM  [dbo].WorkOrderWorkPerformed WoD WITH(NOLOCK)
							         LEFT JOIN dbo.Employee E WITH(NOLOCK) ON @inspectorId = E.EmployeeId
						             LEFT JOIN dbo.Employee E1 WITH(NOLOCK) ON @technicianId = E1.EmployeeId
							 	     LEFT JOIN dbo.TeardownReason wdr WITH(NOLOCK) ON @ReasonId = wdr.TeardownReasonId
							 	     Where WoD.WorkOrderWorkPerformedId = @TableprimaryId
						    end
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
              , @AdhocComments     VARCHAR(150)    = 'InserUpdateSubWorkOrderTeardown' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@TableName, '') AS varchar(100))												   
			   + '@Parameter2 = ''' + CAST(ISNULL(@TableprimaryId, '') AS varchar(100)) 
			   + '@Parameter3 = ''' + CAST(ISNULL(@WorkOrderTeardownId, '') AS varchar(100))
			   + '@Parameter4 = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100))
			   + '@Parameter5 = ''' + CAST(ISNULL(@WorkFlowWorkOrderId, '') AS varchar(100))
			   + '@Parameter6 = ''' + CAST(ISNULL(@ischeckvalue, '') AS varchar(100))
			   + '@Parameter7 = ''' + CAST(ISNULL(@SubWorkOrderTeardownId, '') AS varchar(100))
			   + '@Parameter8 = ''' + CAST(ISNULL(@Memo, '') AS varchar(100))
			   + '@Parameter9 = ''' + CAST(ISNULL(@ReasonId , '') AS varchar(100))
			   + '@Parameter10 = ''' + CAST(ISNULL(@IsDocument , '') AS varchar(100))
			   + '@Parameter11 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100))
			   + '@Parameter12 = ''' + CAST(ISNULL(@CreatedBy, '') AS varchar(100))
			   + '@Parameter13 = ''' + CAST(ISNULL(@UpdatedBy, '') AS varchar(100))
			   + '@Parameter14 = ''' + CAST(ISNULL(@CreatedDate, '') AS varchar(100))
			   + '@Parameter15 = ''' + CAST(ISNULL(@UpdatedDate , '') AS varchar(100))
			   + '@Parameter16 = ''' + CAST(ISNULL(@IsActive , '') AS varchar(100))
			   + '@Parameter17 = ''' + CAST(ISNULL(@IsDeleted , '') AS varchar(100))
			   + '@Parameter18 = ''' + CAST(ISNULL(@airworthinessDirecetives , '') AS varchar(100))
			   + '@Parameter19 = ''' + CAST(ISNULL(@mandatoryService  , '') AS varchar(100))
			   + '@Parameter20 = ''' + CAST(ISNULL(@requestedService  , '') AS varchar(100))
			   + '@Parameter21 = ''' + CAST(ISNULL(@serviceLetters , '') AS varchar(100))
			   + '@Parameter22 = ''' + CAST(ISNULL(@pmaParts, '') AS varchar(100)) 
			   + '@Parameter23 = ''' + CAST(ISNULL(@derRepairs , '') AS varchar(100))
			   + '@Parameter24 = ''' + CAST(ISNULL(@technicianId , '') AS varchar(100))
			   + '@Parameter25 = ''' + CAST(ISNULL(@technicianDate  , '') AS varchar(100))
			   + '@Parameter28 = ''' + CAST(ISNULL(@SubWorkOrderId  , '') AS varchar(100))
			   + '@Parameter29 = ''' + CAST(ISNULL(@SubWOPartNoId , '') AS varchar(100))
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