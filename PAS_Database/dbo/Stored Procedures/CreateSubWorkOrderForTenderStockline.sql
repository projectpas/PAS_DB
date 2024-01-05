
/*************************************************************           
 ** File:   [GetRecevingCustomerList]           
 ** Author:   Hemant Saliya
 ** Description: Create Sub Work Order For Tender Stockline 
 ** Purpose:         
 ** Date:   04-Jan-2024        
          
 ** PARAMETERS:           
    @WorkOrderId BIGINT,
    @WorkOrderPartNoId BIGINT,
    @CreatedBy VARCHAR(100) 
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    04-Jan-2024   Hemant Saliya Created
     
 EXECUTE [GetRecevingCustomerList] 100, 1, null, -1, 1, '', null,null,null,null,null,null,null,null,null,null,null,null,null,null,1,null,null,null,null,0,1,1 
**************************************************************/ 

CREATE PROCEDURE [dbo].[CreateSubWorkOrderForTenderStockline]
-- Add the parameters for the stored procedure here	
@WorkOrderId BIGINT,
@WorkOrderPartNoId BIGINT,
@CreatedBy VARCHAR(100)

AS
BEGIN
		SET NOCOUNT ON;
		SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		DECLARE @MasterCompanyId INT;
		DECLARE @WorkOrderTypeId INT;
		DECLARE @WorkFlowWorkOrderId BIGINT;
		DECLARE @SubWorkOrderNo VARCHAR(20);
		DECLARE @WorkOrderMaterialsId BIGINT;
		DECLARE @StockLineId BIGINT;
		DECLARE @SubWorkOrderStatusId INT;
		DECLARE @currentNo AS BIGINT = 0;  
		DECLARE @SubWOcurrentNo AS BIGINT = 0;
		DECLARE @CodeTypeId INT = 69; -- For SUB WO CODE TYPE

		IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
        BEGIN  
         DROP TABLE #tmpCodePrefixes
        END  
         
        CREATE TABLE #tmpCodePrefixes
        (  
          ID BIGINT NOT NULL IDENTITY,   
          CodePrefixId BIGINT NULL,  
          CodeTypeId BIGINT NULL,  
          CurrentNummber BIGINT NULL,  
          CodePrefix VARCHAR(50) NULL,  
          CodeSufix VARCHAR(50) NULL,  
          StartsFrom BIGINT NULL,  
        )  

		SELECT @MasterCompanyId = MasterCompanyId, @WorkOrderTypeId = WorkOrderTypeId FROM dbo.WorkOrder WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId
		SELECT @SubWorkOrderStatusId = SettingStatusId from dbo.WorkOrderSettings  WITH(NOLOCK) WHERE WorkOrderTypeId = @WorkOrderTypeId

		INSERT INTO #tmpCodePrefixes (CodePrefixId,CodeTypeId,CurrentNummber, CodePrefix, CodeSufix, StartsFrom) 
		SELECT CodePrefixId, CP.CodeTypeId, CurrentNummber, CodePrefix, CodeSufix, StartsFrom   
		FROM dbo.CodePrefixes CP WITH(NOLOCK) JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
		WHERE CT.CodeTypeId IN (@CodeTypeId) AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
		
		SELECT @currentNo = ISNULL(MAX(CurrentNummber), 0) FROM #tmpCodePrefixes
		
		IF (@currentNo <> 0)  
		BEGIN  
		 SET @SubWOcurrentNo = @currentNo + 1  
		END  
		ELSE  
		BEGIN  
		 SET @SubWOcurrentNo = 1  
		END 
		IF(EXISTS (SELECT 1 FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId))  
		BEGIN   
			SET @SubWorkOrderNo = (SELECT * FROM dbo.[udfGenerateCodeNumber](@SubWOcurrentNo, (SELECT CodePrefix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId), (SELECT CodeSufix FROM #tmpCodePrefixes WHERE CodeTypeId = @CodeTypeId)))  
		END
		ELSE   
		BEGIN  
			ROLLBACK TRAN;  
		END  
		
		BEGIN TRY

			BEGIN TRANSACTION
				BEGIN			
					SELECT @MasterCompanyId = WOP.MasterCompanyId, @WorkFlowWorkOrderId = WorkFlowWorkOrderId FROM dbo.WorkOrderPartNumber WOP WITH(NOLOCK) 
					JOIN dbo.WorkOrderWorkFlow WOWF WITH(NOLOCK) ON WOP.ID = WOWF.WorkOrderPartNoId
					WHERE ID = @WorkOrderPartNoId

					SELECT @MasterCompanyId = MasterCompanyId FROM dbo.WorkOrderMaterials WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId

					--CREATE SUB WORK ORDER
					INSERT INTO dbo.SubWorkOrder(WorkOrderId, WorkOrderPartNumberId,OpenDate,WorkOrderMaterialsId,StockLineId,SubWorkOrderStatusId, SubWorkOrderNo,MasterCompanyId,CreatedBy,UpdatedBy,CreatedDate,UpdatedDate,IsActive,IsDeleted)
					SELECT @WorkOrderId, @WorkOrderPartNoId, GETUTCDATE(), @WorkOrderMaterialsId, @StockLineId, @SubWorkOrderStatusId,  @SubWorkOrderNo, @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(),1,0
				
					

					--UPDATE CODE PREFIX FROM SUB WO  
					UPDATE CodePrefixes SET CurrentNummber = @currentNo
					FROM dbo.CodePrefixes CP WITH(NOLOCK) 
					JOIN dbo.CodeTypes CT ON CP.CodeTypeId = CT.CodeTypeId  
					WHERE CT.CodeTypeId = @CodeTypeId AND CP.MasterCompanyId = @MasterCompanyId AND CP.IsActive = 1 AND CP.IsDeleted = 0;  
				
				
				END

				IF OBJECT_ID(N'tempdb..#tmpCodePrefixes') IS NOT NULL  
			    BEGIN  
					DROP TABLE #tmpCodePrefixes 
			    END
			COMMIT  TRANSACTION

		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
					PRINT 'ROLLBACK'
                     ROLLBACK TRAN;
					 SELECT
					ERROR_NUMBER() AS ErrorNumber,
					ERROR_STATE() AS ErrorState,
					ERROR_SEVERITY() AS ErrorSeverity,
					ERROR_PROCEDURE() AS ErrorProcedure,
					ERROR_LINE() AS ErrorLine,
					ERROR_MESSAGE() AS ErrorMessage;
					 DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
				  , @AdhocComments     VARCHAR(150)    = 'GetRecevingCustomerList' 
				  , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WorkOrderId, '') + ''', 
								@Parameter2 = ' + ISNULL(@WorkOrderPartNoId,'') + ', 
								@Parameter3 = ' + ISNULL(@MasterCompanyId ,'') +''
				  , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			=  @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
        END CATCH  	
END