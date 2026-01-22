/*************************************************************           
 ** File:   [USP_CreateWorkOrderLaborHeader]           
 ** Author:   Moin Bloch
 ** Description: This stored procedure is used to Create Work Order Labor Header
 ** Purpose:         
 ** Date:   18/04/2025        
         
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------              
	1    18/04/2025   Moin Bloch       Created
	2	 13/05/2025	  Abhishek Jirawla DataEnteredBy space correction
	3    06/01/2026   Moin Bloch       Added LaborHoursId in WorkOrderLaborHeader
	4    13/01/2026   Amit Ghediya     Get employee TBD for NEO only other company null (Before TBD for all company).

--   EXEC [USP_CreateWorkOrderLaborHeader] 
**************************************************************/
CREATE PROCEDURE [dbo].[USP_CreateWorkOrderLaborHeader]
@tbl_WorkOrderPartNumberType WorkOrderPartNumberType READONLY,
@WorkOrderId BIGINT,
@CreatedBy VARCHAR(256),
@CreatedDate DATETIME2(7),
@MasterCompanyId INT
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
	
	DECLARE @TotalRecord INT = 0,@MinId BIGINT = 1,@DataEnteredBy BIGINT = 0 	  
	DECLARE @HoursorClockorScan INT = 2,@WorkOrderHoursType INT =1,@LaborHoursId INT = 1 
	DECLARE @IsLaborTrackingTurnedOff BIT = 0,@IsTaskCompletedByOne BIT = 0;   
	DECLARE @ExpertiseId AS BIGINT = 0,@EmployeeId AS BIGINT = NULL;  
	DECLARE @TotalWorkHours AS BIGINT = 0.00;  
	DECLARE @ParMasterCompanyId BIGINT = 0;
	DECLARE @MasterCompanyCode VARCHAR(50) = 'NEO';
	 			
	IF OBJECT_ID(N'tempdb..#tempCreateTravelerLabourHeaderForCreateWO') IS NOT NULL
	BEGIN
		DROP TABLE #tempCreateTravelerLabourHeaderForCreateWO
	END	
	
	CREATE TABLE #tempCreateTravelerLabourHeaderForCreateWO
	(
		[PKID] [BIGINT] NOT NULL IDENTITY, 
		[ID] [BIGINT] NULL,		
		[ManagementStructureId] [BIGINT] NULL
	)
	
	SET @ParMasterCompanyId  = (SELECT [MasterCompanyId] FROM [dbo].[Mastercompany] WITH(NOLOCK) WHERE MasterCompanyCode = @MasterCompanyCode)
	IF(@ParMasterCompanyId = @MasterCompanyId)
	BEGIN
		SET @EmployeeId = (SELECT [EmployeeId] FROM [dbo].[Employee] WITH(NOLOCK)  WHERE [FirstName]='TBD' AND [MasterCompanyId] = @MasterCompanyId);
	END
	
	SELECT @ExpertiseId= [EmployeeExpertiseId]  FROM [dbo].[EmployeeExpertise] WITH(NOLOCK) WHERE [MasterCompanyId] = @MasterCompanyId AND [EmpExpCode]='TECHNICIAN' 
	SELECT @DataEnteredBy = ISNULL(EmployeeId,0) FROM [dbo].[Employee] WITH(NOLOCK) WHERE CONCAT(TRIM(REPLACE([FirstName], ' ', '')),'',TRIM(REPLACE([LastName], ' ', ''))) IN (REPLACE(@CreatedBy, ' ', '')) AND [MasterCompanyId]=@MasterCompanyId  

	INSERT INTO #tempCreateTravelerLabourHeaderForCreateWO([ID],[ManagementStructureId])
	SELECT [ID],[ManagementStructureId] FROM @tbl_WorkOrderPartNumberType

	SELECT @TotalRecord = COUNT(*), @MinId = MIN([PKID]) FROM #tempCreateTravelerLabourHeaderForCreateWO

	WHILE @MinId <= @TotalRecord
	BEGIN
	    DECLARE @ID BIGINT = NULL,@WorkFlowWorkOrderId BIGINT = 0,@ManagementStructureId BIGINT = 0
	    
		SELECT @ID = [ID],		       
			   @ManagementStructureId = [ManagementStructureId]
		 FROM #tempCreateTravelerLabourHeaderForCreateWO WHERE [PKID] = @MinId
				
		SELECT @WorkFlowWorkOrderId=ISNULL([WorkFlowWorkOrderId],0) FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE [WorkOrderPartNoId]=@ID;

		SELECT TOP 1 @LaborHoursId = [LaborHoursId], @HoursorClockorScan=[laborHoursMedthodId], @IsLaborTrackingTurnedOff = ISNULL([IsLaborTrackingTurnedOff], 0) FROM [dbo].[LaborOHSettings] WITH(NOLOCK) WHERE [MasterCompanyId]=@MasterCompanyId AND [ManagementStructureId]=@ManagementStructureId  
		
		IF NOT EXISTS (SELECT 1 FROM [dbo].[WorkOrderLaborHeader] WITH(NOLOCK) WHERE [WorkFlowWorkOrderId] = @WorkFlowWorkOrderId AND [WorkOrderId] = @WorkOrderId AND [MasterCompanyId]=@MasterCompanyId)  
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
						,[LaborHoursId]
						)  
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
						,@CreatedDate
						,@CreatedDate
						,1  
						,0  
						,@ExpertiseId  
						,@EmployeeId  
						,@TotalWorkHours  
						,0
						,@IsLaborTrackingTurnedOff
						,@LaborHoursId)  							
		END		
			
		SET @MinId = @MinId + 1
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
              , @AdhocComments     VARCHAR(150)    = 'USP_CreateWorkOrderLaborHeader' 
			  , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@WorkOrderId, '') AS VARCHAR(100)) + 
			                                         '@Parameter2 = ''' + CAST(ISNULL(@CreatedBy, '') AS VARCHAR(100)) +
													 '@Parameter3 = ''' + CAST(ISNULL(@MasterCompanyId, '') AS VARCHAR(100))
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