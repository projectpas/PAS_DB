/*************************************************************           
 ** File:   [USP_AddEdit_WorkOrderTurnArroundTime]           
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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    12/22/2022   Subhash Saliya		Created
     
-- EXEC [USP_AddEdit_WorkOrderTurnArroundTime] 44
**************************************************************/

Create           PROCEDURE [dbo].[USP_CreateTravelerLabourTask_SubWorkorder]
 @WorkOrderId bigint,  
 @SubWorkOrderId bigint,  
 @SubWOPartNoId bigint ,
 @WorkOrderPartId bigint,
 @MasterCompanyId bigint = null,
 @CreatedBy varchar(100)
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

		BEGIN TRY
		BEGIN TRANSACTION
			BEGIN  
				declare @DataEnteredBy bigint =0
				declare @WorkOrderLaborHeaderId bigint =0
                declare @HoursorClockorScan int =2
                declare @WorkOrderHoursType int =1
				declare @IsTaskCompletedByOne bit =0
				DECLARE @ExpertiseId AS BIGINT = 0;
				DECLARE @EmployeeId AS BIGINT = 0;
				DECLARE @TotalWorkHours AS BIGINT = 0.00;
				DECLARE @Traveler_setupid AS BIGINT = 0;
				DECLARE @WorkScopeId AS BIGINT = 0;
				DECLARE @ItemMasterId AS BIGINT = 0;
				DECLARE @TaskStatusId AS BIGINT = 0;
				declare @IstravelerTask bit =0
				declare @ManagementStructureId bigint=0
                
				select top 1 @ManagementStructureId= ManagementStructureId from WorkOrderPartNumber  where ID=@WorkOrderPartId
                select top 1 @ItemMasterId=ItemMasterId,@WorkScopeId=SubWorkOrderScopeId,@IstravelerTask=IsTraveler from SubWorkOrderPartNumber  where SubWOPartNoId=@SubWOPartNoId
				select top 1 @HoursorClockorScan=laborHoursMedthodId from LaborOHSettings  where MasterCompanyId=@MasterCompanyId and ManagementStructureId=@ManagementStructureId
			    select @DataEnteredBy =isnull(EmployeeId,0) from Employee WITH(NOLOCK)  where CONCAT(TRIM(FirstName),'',TRIM(LastName)) IN (replace(@CreatedBy, ' ', '')) and MasterCompanyId=@MasterCompanyId
				select @EmployeeId =isnull(EmployeeId,0) from Employee WITH(NOLOCK)  where FirstName='TBD' and MasterCompanyId=@MasterCompanyId
                select @ExpertiseId=EmployeeExpertiseId from EmployeeExpertise  where MasterCompanyId=@MasterCompanyId and EmpExpCode='TECHNICIAN'
			    select @TaskStatusId=TaskStatusId from TaskStatus  where MasterCompanyId=@MasterCompanyId and Upper(Description)='PENDING'
				 
				 IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId=@ItemMasterId and IsVersionIncrease=0
				 END
				 else IF(EXISTS (SELECT 1 FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0))
				 BEGIN
				    SELECT top 1 @Traveler_setupid= Traveler_setupid FROM Traveler_Setup WHERE WorkScopeId = @WorkScopeId and ItemMasterId is null and IsVersionIncrease=0
				 END


	            IF(@Traveler_setupid >0 and @IstravelerTask=1)
	              begin
	              
	                IF(NOT EXISTS (SELECT 1 FROM SubWorkOrderLaborHeader WHERE SubWOPartNoId = @SubWOPartNoId))
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
                                                 ,GETDATE()
                                                 ,GETDATE()
                                                 ,1
                                                 ,0
                                                 ,@ExpertiseId
                                                 ,@EmployeeId
                                                 ,@TotalWorkHours
                                                 )
	              
	  	           				SELECT @WorkOrderLaborHeaderId = SCOPE_IDENTITY()
	              
                              INSERT INTO [dbo].SubWorkOrderLabor
                                       ([SubWorkOrderLaborHeaderId]
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
									   )
                                SELECT @WorkOrderLaborHeaderId
                                       ,TaskId
                                       ,@ExpertiseId
                                       ,Notes
                                       ,@CreatedBy
                                       ,@CreatedBy
                                       ,GETDATE()
                                       ,GETDATE()
                                       ,1
                                       ,0
                                       ,1
                                       ,0
                                       ,@MasterCompanyId
                                       ,@TaskStatusId
                                        from Traveler_Setup_Task where Traveler_SetupId=@Traveler_SetupId and IsDeleted=0 order by Sequence asc
                  				  	  		
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
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName         = @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END