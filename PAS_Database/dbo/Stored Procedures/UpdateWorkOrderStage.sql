/*************************************************************               
 ** File:  [UpdateWorkOrderStage]          
 ** Author:  Bhargav Saliya
 ** Description: This stored procedure is used to [UpdateWorkOrderStage].    
 ** Purpose:             
 ** Date:   06-Mar-2025          
              
 ** PARAMETERS: @@workOrderShippingId BIGINT    
             
 ** RETURN VALUE:               
 **************************************************************               
 ** Change History               
 **************************************************************               
 ** PR   Date         Author			Change Description                
 ** --   --------     -------		--------------------------------              
    1    06-Mar-2025  Bhargav Saliya		Created    
    2    27-Mar-2025  Bhargav Saliya		Modified    
         
	exec dbo.UpdateWorkOrderStage @WorkOrderId=8412,@WorkOrderStatusId=1,@WorkOrderPartId=8062,@WorkOrderStageId=23,@WorkFlowWorkOrderId=8033,@CreatedBy='BHARGAV S'
************************************************************************/   

CREATE   PROCEDURE [dbo].[UpdateWorkOrderStage]
    @WorkOrderId BIGINT,
    @WorkOrderStatusId INT,
    @WorkOrderPartId BIGINT,
    @WorkOrderStageId BIGINT,
    @WorkFlowWorkOrderId BIGINT,
    @CreatedBy VARCHAR(256)
AS
BEGIN
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

    DECLARE @ItemMasterId BIGINT, @WorkOrderPartIdVar BIGINT, @PartNumber NVARCHAR(255);
    DECLARE @OldStageCode NVARCHAR(50), @OldStageName NVARCHAR(255),@OldStageCodeName NVARCHAR(255);
    DECLARE @NewStageCode NVARCHAR(50), @NewStageName NVARCHAR(255),@NewStageCodeName NVARCHAR(255);
    DECLARE @TemplateBody NVARCHAR(MAX), @ReplaceContent NVARCHAR(MAX);
	DECLARE @ModuleId BIGINT = (SELECT [ModuleId] FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'WorkOrder');
	DECLARE @MasterCompanyId BIGINT = (SELECT MasterCompanyId FROM [dbo].[WorkOrderStage] WITH(NOLOCK) WHERE WorkOrderStageId = @WorkOrderStageId)

    BEGIN TRY
        -- Update WorkOrder Status
        UPDATE WorkOrder SET WorkOrderStatusId = @WorkOrderStatusId WHERE WorkOrderId = @WorkOrderId;

        -- Fetch Old WorkOrderStage
        SELECT @OldStageCode = Code, @OldStageName = Stage
        FROM [dbo].[WorkOrderStage] WITH(NOLOCK)
        WHERE WorkOrderStageId = (SELECT WorkOrderStageId FROM [dbo].[WorkOrderPartNumber] WHERE ID = @WorkOrderPartId);

        -- Fetch New WorkOrderStage
        SELECT @NewStageCode = Code, @NewStageName = Stage
        FROM [dbo].[WorkOrderStage] WITH(NOLOCK)
        WHERE WorkOrderStageId = @WorkOrderStageId;

		SET @OldStageCodeName = @OldStageCode + '-' + @OldStageName;
		SET @NewStageCodeName = @NewStageCode + '-' + @NewStageName;

		 -- Update WorkOrderPartNumber Status and Stage
		--WorkOrderStatusId = @WorkOrderStatusId,
		UPDATE [dbo].[WorkOrderPartNumber] SET WorkOrderStageId = @WorkOrderStageId,WorkOrderStage = @NewStageCodeName WHERE ID = @WorkOrderPartId;

		--UpdateWorkOrderColumns
		EXEC UpdateWorkOrderColumnsWithId @WorkOrderId;

		--AddUpdateWorkOrderTurnArroundTime
		EXEC USP_AddEdit_WorkOrderTurnArroundTime @WorkOrderPartId,@WorkOrderStageId,@CreatedBy;

        -- Determine ItemMasterId
        IF @WorkOrderPartId IS NOT NULL AND @WorkOrderPartId > 0
        BEGIN
            SELECT @ItemMasterId = ItemMasterId
            FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK)
            WHERE ID = @WorkOrderPartId;
        END
        ELSE
        BEGIN
            SELECT @WorkOrderPartIdVar = WorkOrderPartNoId
            FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK)
            WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;

            SELECT @ItemMasterId = ItemMasterId
            FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK)
            WHERE ID = @WorkOrderPartIdVar;
        END

        -- Get Part Number
        SELECT @PartNumber = PartNumber
        FROM [dbo].[ItemMaster] WITH(NOLOCK)
        WHERE ItemMasterId = @ItemMasterId;

        -- Get History Template
        SELECT @TemplateBody = TemplateBody
        FROM [dbo].[HistoryTemplate] WITH(NOLOCK)
        WHERE TemplateCode = 'StageChange';
        -- Replace Template Variables
        SET @ReplaceContent = REPLACE(@TemplateBody, '#MPN#', @PartNumber);
        SET @ReplaceContent = REPLACE(@ReplaceContent, '##OldValue##', @OldStageCode + '-' + @OldStageName);
        SET @ReplaceContent = REPLACE(@ReplaceContent, '##NewValue##', @NewStageCode + '-' + @NewStageName);
    		
		EXEC USP_History @ModuleId,@WorkOrderId,@WorkOrderPartId,@WorkOrderPartId,@OldStageCodeName,@NewStageCodeName,@ReplaceContent,'StageChange',@MasterCompanyId,@CreatedBy,NULL,@CreatedBy,NULL;

    END TRY
    BEGIN CATCH
	DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name()     
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------    
        , @AdhocComments     VARCHAR(150)    = 'UpdateWorkOrderStage'     
        ,@ProcedureParameters VARCHAR(3000) = '@WorkOrderId = ''' + CAST(ISNULL(@WorkOrderId, '') AS varchar(100))      
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
END;