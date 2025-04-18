--sp_helptext USP_CreateTravelerLabourTask

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
       
-- EXEC [USP_CreateTravelerLabourTask] 44  
**************************************************************/  
  
CREATE    PROCEDURE [dbo].[USP_CreateTravelerLabourTask]  
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
				
	SELECT @WorkOrderFormTypeId = ISNULL(WO.[WorkOrderFormTypeId],0) FROM [dbo].[WorkOrder] WO WITH(NOLOCK)	WHERE WO.[WorkOrderId] = @WorkOrderId;

	IF(@WorkOrderFormTypeId = 0)
	BEGIN
                  
    SELECT TOP 1 @ManagementStructureId= ManagementStructureId,@ItemMasterId=ItemMasterId,@WorkScopeId=WorkOrderScopeId,@IstravelerTask=IsTraveler FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID=@WorkOrderPartNoId  
    
	SELECT TOP 1 @HoursorClockorScan=laborHoursMedthodId, @IsLaborTrackingTurnedOff = ISNULL(IsLaborTrackingTurnedOff, 0) FROM [dbo].[LaborOHSettings] WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND ManagementStructureId=@ManagementStructureId  
    
	SELECT @DataEnteredBy = ISNULL(EmployeeId,0) FROM [dbo].[Employee] WITH(NOLOCK)  WHERE CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (REPLACE(@CreatedBy, ' ', '')) AND MasterCompanyId=@MasterCompanyId  
    
	SELECT @EmployeeId = ISNULL(EmployeeId,0) FROM [dbo].[Employee] WITH(NOLOCK)  WHERE FirstName='TBD' AND MasterCompanyId=@MasterCompanyId  
   
    SELECT @ExpertiseId=EmployeeExpertiseId FROM [dbo].[EmployeeExpertise] WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND EmpExpCode='TECHNICIAN'  
   
    SELECT @TaskStatusId=TaskStatusId FROM [dbo].[TaskStatus] WITH(NOLOCK) WHERE MasterCompanyId=@MasterCompanyId AND UPPER(Description)='PENDING'  
       
     IF(EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId AND IsVersionIncrease=0  AND ISNULL(Isactive,1)=1 and ISNULL(IsDeleted,0)=0))  
     BEGIN  
        SELECT top 1 @Traveler_setupid = Traveler_setupid FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId=@ItemMasterId AND IsVersionIncrease=0 AND ISNULL(Isactive,1)=1 AND ISNULL(IsDeleted,0)=0 
     END  
     ELSE IF(EXISTS (SELECT 1 FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId and ItemMasterId IS NULL AND IsVersionIncrease=0 AND ISNULL(Isactive,1)=1 AND ISNULL(IsDeleted,0)=0  ))  
     BEGIN  
        SELECT top 1 @Traveler_setupid = Traveler_setupid FROM [dbo].[Traveler_Setup] WITH(NOLOCK) WHERE WorkScopeId = @WorkScopeId AND ItemMasterId IS NULL AND IsVersionIncrease=0 AND ISNULL(Isactive,1)=1 AND ISNULL(IsDeleted,0)=0   
     END  
     IF(@Traveler_setupid > 0 and @IstravelerTask = 1)  
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
									,[IsLaborTrackingTurnedOff])  
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
									,@IsLaborTrackingTurnedOff)  
                
			SELECT @WorkOrderLaborHeaderId = SCOPE_IDENTITY()  
        END 
		ELSE
		BEGIN
			SELECT @WorkOrderLaborHeaderId = [WorkOrderLaborHeaderId] FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId  
		END		
				
		IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLabor] WITH(NOLOCK) WHERE [WorkOrderLaborHeaderId] = @WorkOrderLaborHeaderId AND [MasterCompanyId]=@MasterCompanyId) AND @WorkOrderLaborHeaderId > 0 
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
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@workorderid, '') + ''  
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