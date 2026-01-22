/*************************************************************           
 ** File:   [USP_CreateTravelerLabourTaskHeader_SubWorkorder]           
 ** Author:   Devendra Shekh
 ** Description: This stored procedure is used Create subworkorder labor header
 ** Date:   21st-April-2025      
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------				--------------------------------          
    1    21-April-2025		Devendra Shekh			Created
	2	 30-MAY-2025		Abhishek Jirawla		Fixed @DataEnteredBy read script
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_CreateTravelerLabourTaskHeader_SubWorkorder]
 @WorkOrderId BIGINT,  
 @SubWorkOrderId BIGINT,  
 @SubWOPartNoId BIGINT ,
 @WorkOrderPartId BIGINT,
 @MasterCompanyId BIGINT = null,
 @CreatedBy VARCHAR(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			DECLARE @DataEnteredBy BIGINT = 0;
            DECLARE @HoursorClockorScan INT = 2;
            DECLARE @WorkOrderHoursType INT = 1;
			DECLARE @IsTaskCompletedByOne BIT =0;
			DECLARE @ExpertiseId AS BIGINT = 0;
			DECLARE @EmployeeId AS BIGINT = 0;
			DECLARE @TotalWorkHours AS BIGINT = 0.00;
			DECLARE @Traveler_setupid AS BIGINT = 0;
			DECLARE @WorkScopeId AS BIGINT = 0;
			DECLARE @ItemMasterId AS BIGINT = 0;
			DECLARE @TaskStatusId AS BIGINT = 0;
			DECLARE @IstravelerTask BIT =0;
			DECLARE @ManagementStructureId BIGINT = 0;
			DECLARE @WorkFlowWorkOrderId BIGINT = 0;
			DECLARE @WorkOrderFormTypeId BIT = 0; 
			DECLARE @IsLaborTrackingTurnedOff BIT = 0; 
				
			SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK)	WHERE WO.[WorkOrderId] = @WorkOrderId;

			IF(@WorkOrderFormTypeId = 0)
			BEGIN
				SELECT TOP 1 @ManagementStructureId = ManagementStructureId FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID = @WorkOrderPartId

				SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkOrderPartNoId = @WorkOrderPartId;
                
				SELECT TOP 1 @ItemMasterId = ItemMasterId, @WorkScopeId = SubWorkOrderScopeId, @IstravelerTask = IsTraveler FROM [dbo].[SubWorkOrderPartNumber] WITH(NOLOCK)  WHERE SubWOPartNoId = @SubWOPartNoId
				
				IF EXISTS(SELECT 1 FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND MasterCompanyId = @MasterCompanyId)
				BEGIN
					SELECT TOP 1 @HoursorClockorScan = HoursorClockorScan, @IsLaborTrackingTurnedOff = ISNULL(IsLaborTrackingTurnedOff, 0)  FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkOrderId] = @WorkOrderId AND [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND MasterCompanyId = @MasterCompanyId
				END
				ELSE
				BEGIN
					SELECT TOP 1 @HoursorClockorScan=laborHoursMedthodId, @IsLaborTrackingTurnedOff = ISNULL(IsLaborTrackingTurnedOff, 0)  FROM [dbo].[LaborOHSettings] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND ManagementStructureId = @ManagementStructureId
				END
			    
				SELECT @DataEnteredBy = ISNULL(EmployeeId,0) FROM [dbo].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(REPLACE([FirstName], ' ', '')),'',TRIM(REPLACE([LastName], ' ', ''))) IN (REPLACE(@CreatedBy, ' ', '')) AND MasterCompanyId = @MasterCompanyId
				
				SELECT @EmployeeId = ISNULL(EmployeeId,0) FROM [dbo].[Employee] WITH(NOLOCK)  WHERE FirstName = 'TBD' AND MasterCompanyId = @MasterCompanyId
                
				SELECT @ExpertiseId = EmployeeExpertiseId FROM [dbo].[EmployeeExpertise] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND EmpExpCode = 'TECHNICIAN'
			   
				SELECT @TaskStatusId = TaskStatusId FROM [dbo].[TaskStatus] WITH(NOLOCK) WHERE MasterCompanyId = @MasterCompanyId AND UPPER(Description) = 'PENDING'
				 
				IF EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId = @ItemMasterId AND IsVersionIncrease = 0)
				BEGIN
					SELECT TOP 1 @Traveler_setupid= Traveler_setupid FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId = @ItemMasterId AND IsVersionIncrease = 0
				END
				ELSE IF(EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId IS NULL AND IsVersionIncrease = 0))
				BEGIN
					SELECT top 1 @Traveler_setupid= Traveler_setupid FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId IS NULL AND IsVersionIncrease=0
				END

				IF(@Traveler_setupid > 0 AND @IstravelerTask = 1)
				BEGIN
	              
					IF NOT EXISTS (SELECT 1 FROM [dbo].[SubWorkOrderLaborHeader] WITH(NOLOCK) WHERE SubWOPartNoId = @SubWOPartNoId)
					BEGIN 
						INSERT INTO [dbo].[SubWorkOrderLaborHeader]
							([WorkOrderId]
							,[SubWorkOrderId]
							,SubWOPartNoId
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
							,[IsLaborTrackingTurnedOff]
							)
						VALUES
							(@WorkOrderId
							,@SubWorkOrderId
							,@SubWOPartNoId
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
							,@IsLaborTrackingTurnedOff
							)
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
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateTravelerLabourTaskHeader_SubWorkorder' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workorderid, '') + ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END