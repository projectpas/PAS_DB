/*************************************************************             
 ** File:   [USP_CreateTravelerLabourTask]             
 ** Author:   Subhash Saliya  
 ** Description: This stored procedure is used Create Stockline ForCustomer RMA     
 ** Purpose:           
 ** Date:   12/22/2022          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author  Change Description              
 ** --   --------     -------  --------------------------------            
    1    12/22/2022   Subhash Saliya  Created
	2    01/09/2025   Moin Bloch 	  ADDED [StandardHours],[StandardMinute]
	3	 01/23/2024	  Moin Bloch	  Modified (check table for WorkOrderFormTypeId)
	4	 04/14/2025	  Devendra Shekh  Added changes for IsLaborTrackingTurnedOff
	5	 04/18/2025	  Moin Bloch	  Modified (for existing [WorkOrderLaborHeader] Data)
	6	 05/30/2025	  Abhishek Jirawla Fixed @DataEnteredBy read script
	7	 10/28/2025	  Moin Bloch	  Modified (for Assign Total Hours to Work Add All Task )
	8	 10/31/2025	  Moin Bloch	  Modified (Allow Labor Entry For Total Hours to Work Add All Task No Need To Check Traveler Setup )
	9	 11/11/2025	  Moin Bloch	  Modified (Add Default Entry Of [DirectLaborOHCost],[BurdaenRatePercentageId],[TotalCostPerHour],[BurdenRateAmount] for Assign Total Hours to Work Add All Task )
	10	 12/23/2025	  Bhargav Saliya  Added case For Dynamic Wo Labour Entry
	11	 12/26/2025	  Bhargav Saliya  Add  Default Entry In [WorkOrderTaskDetails] fro 'All Task'
	12   06/01/2026   Moin Bloch       Added LaborHoursId in WorkOrderLaborHeader
       
-- EXEC [USP_CreateTravelerLabourTask] 10181,10386,10248,1,'JONAS  KAHNWALD'
**************************************************************/  
  
CREATE   PROCEDURE [dbo].[USP_CreateTravelerLabourTask]  
 @WorkOrderId bigint,    
 @WorkOrderPartNoId bigint,    
 @WorkFlowWorkOrderId bigint ,  
 @MasterCompanyId bigint = null,  
 @CreatedBy varchar(100)  
AS  
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
  BEGIN TRY  
  BEGIN TRANSACTION  
   BEGIN    
    DECLARE @DataEnteredBy bigint =0  
    DECLARE @WorkOrderLaborHeaderId bigint =0  
    DECLARE @HoursorClockorScan int =2  
    DECLARE @WorkOrderHoursType int =1  
    DECLARE @IsTaskCompletedByOne bit =0  
    DECLARE @ExpertiseId AS BIGINT = 0;  
    DECLARE @EmployeeId AS BIGINT = 0;  
    DECLARE @TotalWorkHours AS BIGINT = 0.00;  
    DECLARE @Traveler_setupid AS BIGINT = 0;  
    DECLARE @WorkScopeId AS BIGINT = 0;  
    DECLARE @ItemMasterId AS BIGINT = 0;  
    DECLARE @TaskStatusId AS BIGINT = 0;  
    declare @IstravelerTask bit =0  
    declare @ManagementStructureId bigint=0  
	DECLARE @WorkOrderFormTypeId BIT = 0; 
	DECLARE @IsLaborTrackingTurnedOff bit =0; 
	DECLARE @LaborHoursId INT = 0
	DECLARE @TechnicianId BIGINT = NULL  
	DECLARE @HourlyRate DECIMAL(18,2) = 0
	DECLARE @BurdenRatePercentageId BIGINT = NULL
	DECLARE @BurdenRatePercentage DECIMAL(18,2) = 0 
	DECLARE @FlatAmount DECIMAL(18,2) = 0
	DECLARE @BurdenRateAmount DECIMAL(18,2) = 0
	DECLARE @TotalCostPerHour DECIMAL(18,2) = 0
	 DECLARE @WorkOrderTaskId bigint =0

	DECLARE @AssignTotalHourstoWork INT = 2
				
	SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK)	WHERE WO.[WorkOrderId] = @WorkOrderId;
                 
    SELECT TOP 1 @ManagementStructureId = [ManagementStructureId],@ItemMasterId = [ItemMasterId],@WorkScopeId = [WorkOrderScopeId],@IstravelerTask = [IsTraveler],@TechnicianId = [TechnicianId] FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE [ID] = @WorkOrderPartNoId  
    
	SELECT TOP 1 @LaborHoursId = [LaborHoursId], 
	             @HoursorClockorScan=laborHoursMedthodId, 
				 @IsLaborTrackingTurnedOff = ISNULL(IsLaborTrackingTurnedOff, 0) FROM [dbo].[LaborOHSettings] WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND ManagementStructureId=@ManagementStructureId  
    
	SELECT @DataEnteredBy = ISNULL(EmployeeId,0) FROM [dbo].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(REPLACE([FirstName], ' ', '')),'',TRIM(REPLACE([LastName], ' ', ''))) IN (REPLACE(@CreatedBy, ' ', '')) AND MasterCompanyId=@MasterCompanyId  
    
	SELECT @EmployeeId = ISNULL(EmployeeId,0) FROM [dbo].[Employee] WITH(NOLOCK)  WHERE FirstName='TBD' AND MasterCompanyId=@MasterCompanyId  
   
    SELECT @ExpertiseId=EmployeeExpertiseId FROM [dbo].[EmployeeExpertise] WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND EmpExpCode='TECHNICIAN'  
   
    SELECT @TaskStatusId=TaskStatusId FROM [dbo].[TaskStatus] WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND UPPER(Description)='PENDING'  
       
     IF(EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId AND IsVersionIncrease=0  AND ISNULL(Isactive,1)=1 and ISNULL(IsDeleted,0)=0))  
     BEGIN  
        SELECT top 1 @Traveler_setupid = ISNULL([Traveler_setupid],0) FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId=@ItemMasterId AND IsVersionIncrease=0 AND ISNULL(Isactive,1)=1 AND ISNULL(IsDeleted,0)=0 
     END  
     ELSE IF(EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId IS NULL AND IsVersionIncrease=0 AND ISNULL(Isactive,1)=1 AND ISNULL(IsDeleted,0)=0  ))  
     BEGIN  
        SELECT top 1 @Traveler_setupid = ISNULL([Traveler_setupid],0) FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId IS NULL AND IsVersionIncrease=0 AND ISNULL(Isactive,1)=1 AND ISNULL(IsDeleted,0)=0   
     END

	 IF(@TechnicianId > 0)
		 BEGIN
			 IF OBJECT_ID(N'tempdb..#tblBasedOnExpertise') IS NOT NULL
			 BEGIN
				DROP TABLE #tblBasedOnExpertise
 			 END

			 CREATE TABLE #tblBasedOnExpertise
			 (
				[PKID] [BIGINT] NOT NULL IDENTITY, 
				[EmployeeId] [BIGINT] NULL,
				[EmployeeCode] [VARCHAR](50) NULL, 
				[StationId]	[BIGINT] NULL,
				[StationName] [VARCHAR](50) NULL, 
				[FirstName] [VARCHAR](50) NULL, 
				[LastName]	[VARCHAR](50) NULL, 
				[MiddleName] [VARCHAR](50) NULL, 
				[Name]   [VARCHAR](100) NULL, 
				[IsWorksInShop] [BIT] NULL, 
				[HourlyRate] [DECIMAL](18,2)  NULL, 
				[BurdenRatePercentageId] [BIGINT] NULL,
				[BurdenRatePercentage] [DECIMAL](18,2)  NULL, 
				[FlatAmount] [DECIMAL](18,2)  NULL, 
				[BurdenRateAmount] [DECIMAL](18,2)  NULL, 
				[TotalCostPerHour] [DECIMAL](18,2)  NULL
			 )

			 INSERT INTO #tblBasedOnExpertise		
			 EXEC [dbo].[USP_Employee_GetEmployeeBasedOnExpertise] @ExpertiseId,@ManagementStructureId,'','0',0,0

			 SELECT TOP 1 @HourlyRate = ISNULL(E.[HourlyRate],0), 
					@BurdenRatePercentageId = E.[BurdenRatePercentageId],
					@BurdenRatePercentage = ISNULL(E.[BurdenRatePercentage],0),
					@FlatAmount = ISNULL(E.[FlatAmount],0),
					@BurdenRateAmount = ISNULL(E.[BurdenRateAmount],0),
					@TotalCostPerHour = ISNULL(E.[TotalCostPerHour],0)
			   FROM #tblBasedOnExpertise E WHERE E.[EmployeeId] = @TechnicianId		   
	 END
	 IF(@WorkOrderFormTypeId = 0)
	 BEGIN

		 IF(@Traveler_setupid > 0 AND @IstravelerTask = 1)  
		 BEGIN  
			IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId) 
			BEGIN   
				INSERT INTO [dbo].[WorkOrderLaborHeader]  
										([WorkOrderId]  
										,[WorkFlowWorkOrderId]  
										,[DataEnteredBy]  
										,[HoursorClockorScan]  
										,[IsTaskCompletedByOne]  
										,[WorkOrderHoursType]  
										,[LabourMemo]  
										,[MasterCompanyId]  
										,[CreatedBy]  
										,[UpdatedBy]  
										,[CreatedDate]  
										,[UpdatedDate]  
										,[IsActive]  
										,[IsDeleted]  
										,[ExpertiseId]  
										,[EmployeeId]  
										,[TotalWorkHours]  
										,[WOPartNoId]
										,[IsLaborTrackingTurnedOff]
										,[LaborHoursId])  
								  VALUES  
										(@WorkOrderId  
										,@WorkFlowWorkOrderId  
										,@DataEnteredBy  
										,@HoursorClockorScan  
										,@IsTaskCompletedByOne  
										,@WorkOrderHoursType  
										,''  
										,@MasterCompanyId  
										,@CreatedBy  
										,@CreatedBy  
										,GETUTCDATE()  
										,GETUTCDATE()  
										,1  
										,0  
										,@ExpertiseId  
										,@EmployeeId  
										,@TotalWorkHours  
										,0
										,@IsLaborTrackingTurnedOff
										,@LaborHoursId)  
                
				SELECT @WorkOrderLaborHeaderId = SCOPE_IDENTITY()  
			END 
			ELSE
			BEGIN
				SELECT @WorkOrderLaborHeaderId = [WorkOrderLaborHeaderId] FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId  
			END		
				
			IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLabor] WITH(NOLOCK) WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId AND [MasterCompanyId]=@MasterCompanyId) AND @WorkOrderLaborHeaderId > 0 
			BEGIN 
				IF(@LaborHoursId != @AssignTotalHourstoWork)
				BEGIN
					INSERT INTO [dbo].[WorkOrderLabor]  
							([WorkOrderLaborHeaderId]  
							,[TaskId]  
							,[ExpertiseId]  
							,TaskInstruction  
							,[CreatedBy]  
							,[UpdatedBy]  
							,[CreatedDate]  
							,[UpdatedDate]  
							,[IsActive]  
							,[IsDeleted]  
							,[BillableId]  
							,[IsFromWorkFlow]  
							,[MasterCompanyId]  
							,[TaskStatusId]
							,[StandardHours]
							,[StandardMinute])  
					  SELECT @WorkOrderLaborHeaderId  
							 ,TST.[TaskId]  
							 ,@ExpertiseId  
							 ,TST.[Notes]  
							 ,@CreatedBy  
							 ,@CreatedBy  
							 ,GETUTCDATE()  
							 ,GETUTCDATE()  
							 ,1  
							 ,0  
							 ,1  
							 ,0  
							 ,@MasterCompanyId  
							 ,@TaskStatusId  
							 ,TSK.[StandardHours]
							 ,TSK.[StandardMinute]
						FROM [dbo].[Traveler_Setup_Task] TST WITH(NOLOCK) 
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON TST.TaskId = TSK.TaskId 
					  WHERE TST.Traveler_SetupId=@Traveler_SetupId AND TST.IsDeleted = 0 ORDER BY TST.[Sequence] ASC  
				END

				IF(@LaborHoursId = @AssignTotalHourstoWork)
				BEGIN	
					IF NOT EXISTS(SELECT 1 FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0)
					BEGIN
						INSERT INTO [dbo].[Task]([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],[Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
					 					 VALUES ('ALL TASK','',@MasterCompanyId,'AUTO SCRIPT','AUTO SCRIPT',GETUTCDATE(),GETUTCDATE(),1,0,(SELECT (MAX([Sequence]) + 1) FROM [dbo].[Task] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId),1,NULL,NULL,0,0,0,0,1,0,1);						
					END

					INSERT INTO [dbo].[WorkOrderLabor]  
							([WorkOrderLaborHeaderId]  
							,[TaskId]  
							,[ExpertiseId]  
							,[EmployeeId]
							,[TaskInstruction]  
							,[CreatedBy]  
							,[UpdatedBy]  
							,[CreatedDate]  
							,[UpdatedDate]  
							,[IsActive]  
							,[IsDeleted]  
							,[BillableId]  
							,[IsFromWorkFlow]  
							,[MasterCompanyId]  
							,[TaskStatusId]
							,[StandardHours]
							,[StandardMinute]
							,[DirectLaborOHCost]
							,[BurdaenRatePercentageId]
							,[TotalCostPerHour]
							,[BurdenRateAmount]
							)  
					  SELECT @WorkOrderLaborHeaderId  
							 ,TSK.[TaskId]  
							 ,@ExpertiseId  
							 ,CASE WHEN @TechnicianId > 0 THEN @TechnicianId ELSE @EmployeeId END
							 ,TSK.[Memo]  
							 ,@CreatedBy  
							 ,@CreatedBy  
							 ,GETUTCDATE()  
							 ,GETUTCDATE()  
							 ,1  
							 ,0  
							 ,1  
							 ,0  
							 ,@MasterCompanyId  
							 ,@TaskStatusId  
							 ,TSK.[StandardHours]
							 ,TSK.[StandardMinute]
							 ,CASE WHEN @TechnicianId > 0 THEN @HourlyRate ELSE 0 END
							 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRatePercentageId ELSE NULL END
							 ,CASE WHEN @TechnicianId > 0 THEN @TotalCostPerHour ELSE 0 END
							 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRateAmount ELSE 0 END
						FROM [dbo].[Task] TSK WITH(NOLOCK) 
					  WHERE TSK.[Description] = 'ALL TASK'  AND TSK.[MasterCompanyId] = @MasterCompanyId AND TSK.[IsDeleted] = 0
				END
			END			   
		 END
		 ELSE
		 BEGIN
			IF(@Traveler_setupid = 0 AND @IstravelerTask = 1)
			BEGIN
				IF(@LaborHoursId = @AssignTotalHourstoWork)
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId) 
					BEGIN   
						INSERT INTO [dbo].[WorkOrderLaborHeader]  
										([WorkOrderId]  
										,[WorkFlowWorkOrderId]  
										,[DataEnteredBy]  
										,[HoursorClockorScan]  
										,[IsTaskCompletedByOne]  
										,[WorkOrderHoursType]  
										,[LabourMemo]  
										,[MasterCompanyId]  
										,[CreatedBy]  
										,[UpdatedBy]  
										,[CreatedDate]  
										,[UpdatedDate]  
										,[IsActive]  
										,[IsDeleted]  
										,[ExpertiseId]  
										,[EmployeeId]  
										,[TotalWorkHours]  
										,[WOPartNoId]
										,[IsLaborTrackingTurnedOff]
										,[LaborHoursId])  
								  VALUES  
										(@WorkOrderId  
										,@WorkFlowWorkOrderId  
										,@DataEnteredBy  
										,@HoursorClockorScan  
										,@IsTaskCompletedByOne  
										,@WorkOrderHoursType  
										,''  
										,@MasterCompanyId  
										,@CreatedBy  
										,@CreatedBy  
										,GETUTCDATE()  
										,GETUTCDATE()  
										,1  
										,0  
										,@ExpertiseId  
										,@EmployeeId  
										,@TotalWorkHours  
										,0
										,@IsLaborTrackingTurnedOff
										,@LaborHoursId)  
                
						SELECT @WorkOrderLaborHeaderId = SCOPE_IDENTITY()  
					END 
					ELSE
					BEGIN
						SELECT @WorkOrderLaborHeaderId = [WorkOrderLaborHeaderId] FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId  
					END
					IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLabor] WITH(NOLOCK) WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId AND [MasterCompanyId]=@MasterCompanyId) AND @WorkOrderLaborHeaderId > 0 
					BEGIN 
						IF NOT EXISTS(SELECT 1 FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0)
						BEGIN	
							INSERT INTO [dbo].[Task]([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],[Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
											 VALUES ('ALL TASK','',@MasterCompanyId,'AUTO SCRIPT','AUTO SCRIPT',GETUTCDATE(),GETUTCDATE(),1,0,(SELECT (MAX([Sequence]) + 1) FROM [dbo].[Task] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId),1,NULL,NULL,0,0,0,0,1,0,1);						
						END

						INSERT INTO [dbo].[WorkOrderLabor]  
									([WorkOrderLaborHeaderId]  
									,[TaskId]  
									,[ExpertiseId]  
									,[EmployeeId]
									,[TaskInstruction]  
									,[CreatedBy]  
									,[UpdatedBy]  
									,[CreatedDate]  
									,[UpdatedDate]  
									,[IsActive]  
									,[IsDeleted]  
									,[BillableId]  
									,[IsFromWorkFlow]  
									,[MasterCompanyId]  
									,[TaskStatusId]
									,[StandardHours]
									,[StandardMinute]
									,[DirectLaborOHCost]
									,[BurdaenRatePercentageId]
									,[TotalCostPerHour]
									,[BurdenRateAmount]								
									)  
							  SELECT @WorkOrderLaborHeaderId  
									 ,TSK.[TaskId]  
									 ,@ExpertiseId  
									 ,CASE WHEN @TechnicianId > 0 THEN @TechnicianId ELSE @EmployeeId END
									 ,TSK.[Memo]  
									 ,@CreatedBy  
									 ,@CreatedBy  
									 ,GETUTCDATE()  
									 ,GETUTCDATE()  
									 ,1  
									 ,0  
									 ,1  
									 ,0  
									 ,@MasterCompanyId  
									 ,@TaskStatusId  
									 ,TSK.[StandardHours]
									 ,TSK.[StandardMinute]
									 ,CASE WHEN @TechnicianId > 0 THEN @HourlyRate ELSE 0 END
									 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRatePercentageId ELSE NULL END
									 ,CASE WHEN @TechnicianId > 0 THEN @TotalCostPerHour ELSE 0 END
									 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRateAmount ELSE 0 END
								FROM [dbo].[Task] TSK WITH(NOLOCK) 
							  WHERE TSK.[Description] = 'ALL TASK'  AND TSK.[MasterCompanyId] = @MasterCompanyId AND TSK.[IsDeleted] = 0					
					END
				END
			END
		  END
	END
	ELSE
	BEGIN
		DECLARE @TaskId BIGINT,@Description VARCHAR(200) = NULL;	 

		 IF(@Traveler_setupid > 0 AND @IstravelerTask = 1)  
		 BEGIN  
			IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId) 
			BEGIN   
				INSERT INTO [dbo].[WorkOrderLaborHeader]  
										([WorkOrderId]  
										,[WorkFlowWorkOrderId]  
										,[DataEnteredBy]  
										,[HoursorClockorScan]  
										,[IsTaskCompletedByOne]  
										,[WorkOrderHoursType]  
										,[LabourMemo]  
										,[MasterCompanyId]  
										,[CreatedBy]  
										,[UpdatedBy]  
										,[CreatedDate]  
										,[UpdatedDate]  
										,[IsActive]  
										,[IsDeleted]  
										,[ExpertiseId]  
										,[EmployeeId]  
										,[TotalWorkHours]  
										,[WOPartNoId]
										,[IsLaborTrackingTurnedOff]
										,[LaborHoursId])  
								  VALUES  
										(@WorkOrderId  
										,@WorkFlowWorkOrderId  
										,@DataEnteredBy  
										,@HoursorClockorScan  
										,@IsTaskCompletedByOne  
										,@WorkOrderHoursType  
										,''  
										,@MasterCompanyId  
										,@CreatedBy  
										,@CreatedBy  
										,GETUTCDATE()  
										,GETUTCDATE()  
										,1  
										,0  
										,@ExpertiseId  
										,@EmployeeId  
										,@TotalWorkHours  
										,0
										,@IsLaborTrackingTurnedOff
										,@LaborHoursId)  
                
				SELECT @WorkOrderLaborHeaderId = SCOPE_IDENTITY()  
			END 
			ELSE
			BEGIN
				SELECT @WorkOrderLaborHeaderId = [WorkOrderLaborHeaderId] FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId  
			END		
				
			IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLabor] WITH(NOLOCK) WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId AND [MasterCompanyId]=@MasterCompanyId) AND @WorkOrderLaborHeaderId > 0 
			BEGIN 
				IF(@LaborHoursId != @AssignTotalHourstoWork)
				BEGIN
					INSERT INTO [dbo].[WorkOrderLabor]  
							([WorkOrderLaborHeaderId]  
							,[TaskId]  
							,[ExpertiseId]  
							,TaskInstruction  
							,[CreatedBy]  
							,[UpdatedBy]  
							,[CreatedDate]  
							,[UpdatedDate]  
							,[IsActive]  
							,[IsDeleted]  
							,[BillableId]  
							,[IsFromWorkFlow]  
							,[MasterCompanyId]  
							,[TaskStatusId]
							,[StandardHours]
							,[StandardMinute])  
					  SELECT @WorkOrderLaborHeaderId  
							 ,TST.[TaskId]  
							 ,@ExpertiseId  
							 ,TST.[Notes]  
							 ,@CreatedBy  
							 ,@CreatedBy  
							 ,GETUTCDATE()  
							 ,GETUTCDATE()  
							 ,1  
							 ,0  
							 ,1  
							 ,0  
							 ,@MasterCompanyId  
							 ,@TaskStatusId  
							 ,TSK.[StandardHours]
							 ,TSK.[StandardMinute]
						FROM [dbo].[Traveler_Setup_Task] TST WITH(NOLOCK) 
					LEFT JOIN [dbo].[Task] TSK WITH(NOLOCK) ON TST.TaskId = TSK.TaskId 
					  WHERE TST.Traveler_SetupId=@Traveler_SetupId AND TST.IsDeleted = 0 ORDER BY TST.[Sequence] ASC  
				END

				IF(@LaborHoursId = @AssignTotalHourstoWork)
				BEGIN	
					IF NOT EXISTS(SELECT 1 FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0)
					BEGIN
						INSERT INTO [dbo].[Task]([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],[Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
					 					 VALUES ('ALL TASK','',@MasterCompanyId,'AUTO SCRIPT','AUTO SCRIPT',GETUTCDATE(),GETUTCDATE(),1,0,(SELECT (MAX([Sequence]) + 1) FROM [dbo].[Task] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId),1,NULL,NULL,0,0,0,0,1,0,1);						
					END

					SELECT @TaskId = TaskId,@Description = [Description] FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0;

					IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderTask] WHERE [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0)
					BEGIN
						INSERT INTO [dbo].[WorkOrderTask](WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,WorkOrderPartNumberId,
						SequenceNumber,OpenDate,OpenBy,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
						VALUES(@WorkOrderId,@WorkFlowWorkOrderId,@TaskId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@WorkOrderPartNoId,
						1,NULL,NULL,0,NULL,@Description,0);

						SELECT @WorkOrderTaskId = SCOPE_IDENTITY() 
					END
					ELSE
					BEGIN
						SELECT @WorkOrderTaskId = [WorkOrderTaskId] FROM [dbo].[WorkOrderTask] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId  
					END	

					IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderTaskDetails] WHERE [WorkOrderTaskId] = @WorkOrderTaskId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0)
					BEGIN
						INSERT INTO [dbo].[WorkOrderTaskDetails](WorkOrderTaskId,OpenDate,OpenBy,TechId,TechName,TechUpdatedDate,InspectorId,InspectorName,InspectorUpdatedDate,
						Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,PrintInWO,PrintInWOQ,IsPrintInspector,IsPrintTechnician,IsPrintAdmin)
						VALUES(@WorkOrderTaskId,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,'','',NULL,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,0,0,1,1,0);
					END

					INSERT INTO [dbo].[WorkOrderLabor]  
							([WorkOrderLaborHeaderId]  
							,[TaskId]  
							,[ExpertiseId]  
							,[EmployeeId]
							,[TaskInstruction]  
							,[CreatedBy]  
							,[UpdatedBy]  
							,[CreatedDate]  
							,[UpdatedDate]  
							,[IsActive]  
							,[IsDeleted]  
							,[BillableId]  
							,[IsFromWorkFlow]  
							,[MasterCompanyId]  
							,[TaskStatusId]
							,[StandardHours]
							,[StandardMinute]
							,[DirectLaborOHCost]
							,[BurdaenRatePercentageId]
							,[TotalCostPerHour]
							,[BurdenRateAmount]
							)  
					  SELECT @WorkOrderLaborHeaderId  
							 ,@WorkOrderTaskId 
							 ,@ExpertiseId  
							 ,CASE WHEN @TechnicianId > 0 THEN @TechnicianId ELSE @EmployeeId END
							 ,TSK.[Memo]  
							 ,@CreatedBy  
							 ,@CreatedBy  
							 ,GETUTCDATE()  
							 ,GETUTCDATE()  
							 ,1  
							 ,0  
							 ,1  
							 ,0  
							 ,@MasterCompanyId  
							 ,@TaskStatusId  
							 ,TSK.[StandardHours]
							 ,TSK.[StandardMinute]
							 ,CASE WHEN @TechnicianId > 0 THEN @HourlyRate ELSE 0 END
							 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRatePercentageId ELSE NULL END
							 ,CASE WHEN @TechnicianId > 0 THEN @TotalCostPerHour ELSE 0 END
							 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRateAmount ELSE 0 END
						FROM [dbo].[Task] TSK WITH(NOLOCK) 
					  WHERE TSK.[Description] = 'ALL TASK'  AND TSK.[MasterCompanyId] = @MasterCompanyId AND TSK.[IsDeleted] = 0
				END
			END			   
		 END
		 ELSE
		 BEGIN
			IF(@Traveler_setupid = 0 AND @IstravelerTask = 1)
			BEGIN
				IF(@LaborHoursId = @AssignTotalHourstoWork)
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId) 
					BEGIN   
						INSERT INTO [dbo].[WorkOrderLaborHeader]  
										([WorkOrderId]  
										,[WorkFlowWorkOrderId]  
										,[DataEnteredBy]  
										,[HoursorClockorScan]  
										,[IsTaskCompletedByOne]  
										,[WorkOrderHoursType]  
										,[LabourMemo]  
										,[MasterCompanyId]  
										,[CreatedBy]  
										,[UpdatedBy]  
										,[CreatedDate]  
										,[UpdatedDate]  
										,[IsActive]  
										,[IsDeleted]  
										,[ExpertiseId]  
										,[EmployeeId]  
										,[TotalWorkHours]  
										,[WOPartNoId]
										,[IsLaborTrackingTurnedOff]
										,[LaborHoursId])  
								  VALUES  
										(@WorkOrderId  
										,@WorkFlowWorkOrderId  
										,@DataEnteredBy  
										,@HoursorClockorScan  
										,@IsTaskCompletedByOne  
										,@WorkOrderHoursType  
										,''  
										,@MasterCompanyId  
										,@CreatedBy  
										,@CreatedBy  
										,GETUTCDATE()  
										,GETUTCDATE()  
										,1  
										,0  
										,@ExpertiseId  
										,@EmployeeId  
										,@TotalWorkHours  
										,0
										,@IsLaborTrackingTurnedOff
										,@LaborHoursId)  
                
						SELECT @WorkOrderLaborHeaderId = SCOPE_IDENTITY()  
					END 
					ELSE
					BEGIN
						SELECT @WorkOrderLaborHeaderId = [WorkOrderLaborHeaderId] FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId  
					END
					IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLabor] WITH(NOLOCK) WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId AND [MasterCompanyId]=@MasterCompanyId) AND @WorkOrderLaborHeaderId > 0 
					BEGIN 
						IF NOT EXISTS(SELECT 1 FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId AND [IsDeleted] = 0)
						BEGIN	
							INSERT INTO [dbo].[Task]([Description],[Memo],[MasterCompanyId],[CreatedBy],[UpdatedBy],[CreatedDate],[UpdatedDate],[IsActive],[IsDeleted],[Sequence],[IsTravelerTask],[Descrepancy],[Resolution],[StandardHours],[StandardMinute],[IsPrintInWO],[IsPrintInWOQ],[IsPrintInspector],[IsPrintTechnician],[IsPrintAdmin])
											 VALUES ('ALL TASK','',@MasterCompanyId,'AUTO SCRIPT','AUTO SCRIPT',GETUTCDATE(),GETUTCDATE(),1,0,(SELECT (MAX([Sequence]) + 1) FROM [dbo].[Task] WITH (NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId),1,NULL,NULL,0,0,0,0,1,0,1);						
						END

						SELECT @TaskId = TaskId,@Description = [Description] FROM [dbo].[Task] WHERE [Description] = 'ALL TASK' AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0;

						IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderTask] WHERE [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0)
						BEGIN
							INSERT INTO [dbo].[WorkOrderTask](WorkOrderId,WorkFlowWorkOrderId,TaskId,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,WorkOrderPartNumberId,
							SequenceNumber,OpenDate,OpenBy,IsIncludeInPrint,HasInstruction,TaskName,IsFromWorkFlow)
							VALUES(@WorkOrderId,@WorkFlowWorkOrderId,@TaskId,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,@WorkOrderPartNoId,
							1,NULL,NULL,0,NULL,@Description,0);

							SELECT @WorkOrderTaskId = SCOPE_IDENTITY() 
						END
						ELSE
						BEGIN
							SELECT @WorkOrderTaskId = [WorkOrderTaskId] FROM [dbo].[WorkOrderTask] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId  
						END

						IF NOT EXISTS(SELECT 1 FROM [dbo].[WorkOrderTaskDetails] WHERE [WorkOrderTaskId] = @WorkOrderTaskId AND [MasterCompanyId] = @MasterCompanyId AND ISNULL([IsDeleted],0) = 0)
						BEGIN
							INSERT INTO [dbo].[WorkOrderTaskDetails](WorkOrderTaskId,OpenDate,OpenBy,TechId,TechName,TechUpdatedDate,InspectorId,InspectorName,InspectorUpdatedDate,
							Descrepancy,Resolution,HasInstruction,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted,PrintInWO,PrintInWOQ,IsPrintInspector,IsPrintTechnician,IsPrintAdmin)
							VALUES(@WorkOrderTaskId,NULL,'',NULL,NULL,NULL,NULL,NULL,NULL,'','',NULL,@MasterCompanyId,@CreatedBy,@CreatedBy,GETUTCDATE(),GETUTCDATE(),1,0,0,0,1,1,0);
						END

						INSERT INTO [dbo].[WorkOrderLabor]  
									([WorkOrderLaborHeaderId]  
									,[TaskId]  
									,[ExpertiseId]  
									,[EmployeeId]
									,[TaskInstruction]  
									,[CreatedBy]  
									,[UpdatedBy]  
									,[CreatedDate]  
									,[UpdatedDate]  
									,[IsActive]  
									,[IsDeleted]  
									,[BillableId]  
									,[IsFromWorkFlow]  
									,[MasterCompanyId]  
									,[TaskStatusId]
									,[StandardHours]
									,[StandardMinute]
									,[DirectLaborOHCost]
									,[BurdaenRatePercentageId]
									,[TotalCostPerHour]
									,[BurdenRateAmount]								
									)  
							  SELECT @WorkOrderLaborHeaderId  
									 ,@WorkOrderTaskId  
									 ,@ExpertiseId  
									 ,CASE WHEN @TechnicianId > 0 THEN @TechnicianId ELSE @EmployeeId END
									 ,TSK.[Memo]  
									 ,@CreatedBy  
									 ,@CreatedBy  
									 ,GETUTCDATE()  
									 ,GETUTCDATE()  
									 ,1  
									 ,0  
									 ,1  
									 ,0  
									 ,@MasterCompanyId  
									 ,@TaskStatusId  
									 ,TSK.[StandardHours]
									 ,TSK.[StandardMinute]
									 ,CASE WHEN @TechnicianId > 0 THEN @HourlyRate ELSE 0 END
									 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRatePercentageId ELSE NULL END
									 ,CASE WHEN @TechnicianId > 0 THEN @TotalCostPerHour ELSE 0 END
									 ,CASE WHEN @TechnicianId > 0 THEN @BurdenRateAmount ELSE 0 END
								FROM [dbo].[Task] TSK WITH(NOLOCK) 
							  WHERE TSK.[Description] = 'ALL TASK'  AND TSK.[MasterCompanyId] = @MasterCompanyId AND TSK.[IsDeleted] = 0					
					END
				END
			END
		  END
	END
   END  
  COMMIT  TRANSACTION  
  
  END TRY      
  BEGIN CATCH        
   IF @@trancount > 0  
    --PRINT 'ROLLBACK'  
    ROLLBACK TRAN;  
    DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()   
  
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------  
              , @AdhocComments     VARCHAR(150)    = 'USP_AddUpdateTravelerSetupHeader'                 
			  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ''' + CAST(ISNULL(@workorderid, '') AS VARCHAR(100)) 
              , @ApplicationName VARCHAR(100) = 'PAS'  
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------  
  
              exec spLogException   
                       @DatabaseName   = @DatabaseName  
                     , @AdhocComments   = @AdhocComments  
                     , @ProcedureParameters  = @ProcedureParameters  
                     , @ApplicationName         = @ApplicationName  
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;  
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)  
              RETURN(1);  
  END CATCH  
END