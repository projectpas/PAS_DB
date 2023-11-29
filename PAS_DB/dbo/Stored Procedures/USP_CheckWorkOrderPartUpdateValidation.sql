/********************************************************************
 ** File:   [USP_CheckWorkOrderPartUpdateValidation]           
 ** Author:  VISHAL SUTHAR
 ** Description: This stored procedure is used ckeck Duplicate WorkOrder Validation
 ** Purpose:         
 ** Date:   30/05/2023  
          
 ** PARAMETERS: @WorkOrderId BIGINT, @ItemMasterId BIGINT, @SerialNumber VARCHAR(50), @ConditionId BIGINT, @MasterCompanyId INT
     
 ***********************************************************************    
 ** Change History           
 *********************************************************************** 
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		------------------------------------
    1    30/05/2023   VISHAL SUTHAR     Created
     
-- EXEC USP_CheckWorkOrderPartUpdateValidation 3402, 20769, 'wfgjertyuh', 180, 11
************************************************************************/
CREATE   PROCEDURE [dbo].[USP_CheckWorkOrderPartUpdateValidation]
	@WorkOrderId BIGINT,
	@ItemMasterId BIGINT,
	@SerialNumber VARCHAR(50),
	@ConditionId BIGINT,
	@WorkOrderPartNumberId BIGINT,
	@MasterCompanyId INT
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;	
	BEGIN TRY
		DECLARE @qtyissue INT = 0;

		IF OBJECT_ID(N'tempdb..#tmpWOErrorMessages') IS NOT NULL
		BEGIN
			DROP TABLE #tmpWOErrorMessages
		END

		CREATE TABLE #tmpWOErrorMessages
		(
			ID BIGINT NOT NULL IDENTITY,
			[ValidationMessage] NVARCHAR(MAX) NULL
		)

		IF NOT EXISTS (SELECT TOP 1 * FROM DBO.WorkOrderPartNumber WOP WITH (NOLOCK) WHERE ID = @WorkOrderPartNumberId AND WOP.ItemMasterId = @ItemMasterId AND WOP.ConditionId = @ConditionId)
		BEGIN
			SELECT @qtyissue = SUM(ISNULL(QuantityIssued, 0))
			FROM DBO.WorkOrderMaterials WOM WITH(NOLOCK)
			WHERE WOM.WorkOrderId = @WorkOrderId AND WOM.MasterCompanyId = @MasterCompanyId;

			IF (ISNULL(@qtyissue, 0) > 0)
			BEGIN
				INSERT INTO #tmpWOErrorMessages
				SELECT 'All material must be unissued' AS ErrorMessage;
			END

			DECLARE @OriginalItemMasterId BIGINT = 0;
			DECLARE @WoWfId BIGINT = 0;
			DECLARE @TotalLaborCost DECIMAL(18, 2) = 0;

			SELECT @WoWfId = WorkFlowWorkOrderId FROM DBO.WorkOrderWorkFlow WHERE WorkOrderId = @WorkOrderId AND WorkOrderPartNoId = @WorkOrderPartNumberId AND MasterCompanyId = @MasterCompanyId;
		
			SELECT @TotalLaborCost = SUM(WOL.TotalCost) FROM DBO.WorkOrderLaborHeader WOLH (NOLOCK)
			INNER JOIN DBO.WorkOrderLabor WOL (NOLOCK) ON WOLH.WorkOrderLaborHeaderId = WOL.WorkOrderLaborHeaderId
			WHERE WOLH.WorkFlowWorkOrderId = @WoWfId AND WOLH.MasterCompanyId = @MasterCompanyId;

			IF (ISNULL(@TotalLaborCost, 0) > 0)
			BEGIN
				INSERT INTO #tmpWOErrorMessages
				SELECT 'All labor hours (and cost) must be removed' AS ErrorMessage;
			END

			DECLARE @ChargesCost DECIMAL(18, 2) = 0;
			DECLARE @FreightCost DECIMAL(18, 2) = 0;

			SELECT @ChargesCost = WOC.ChargesCost, @FreightCost = WOC.FreightCost FROM DBO.WorkOrderMPNCostDetails WOC (NOLOCK)
			WHERE WOC.WorkOrderId = @WorkOrderId AND WOC.WOPartNoId = @WorkOrderPartNumberId AND WOC.MasterCompanyId = @MasterCompanyId;

			IF (ISNULL(@ChargesCost, 0) > 0)
			BEGIN
				INSERT INTO #tmpWOErrorMessages
				SELECT 'Charges tab should have no cost' AS ErrorMessage;
			END

			IF (ISNULL(@FreightCost, 0) > 0)
			BEGIN
				INSERT INTO #tmpWOErrorMessages
				SELECT 'Freight tab should have no cost' AS ErrorMessage;
			END

			IF EXISTS (SELECT TOP 1 * FROM DBO.WorkOrderShippingItem WOS (NOLOCK) WHERE WOS.WorkOrderPartNumId = @WorkOrderPartNumberId AND MasterCompanyId = @MasterCompanyId)
			BEGIN
				INSERT INTO #tmpWOErrorMessages
				SELECT 'This part is already shipped' AS ErrorMessage;
			END

			IF EXISTS (SELECT TOP 1 * FROM DBO.WorkOrderBillingInvoicingItem WOB (NOLOCK) WHERE WOB.WorkOrderPartId = @WorkOrderPartNumberId AND MasterCompanyId = @MasterCompanyId)
			BEGIN
				INSERT INTO #tmpWOErrorMessages
				SELECT 'This part is already invoiced' AS ErrorMessage;
			END
		END

		SELECT ValidationMessage FROM #tmpWOErrorMessages;
	END TRY 
	BEGIN CATCH      
		IF @@trancount > 0
		PRINT 'ROLLBACK'
				ROLLBACK TRANSACTION;
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_CheckWorkOrderPartUpdateValidation' 
              , @ProcedureParameters VARCHAR(3000)  = '@WorkOrderId = '''+ CAST(ISNULL(@WorkOrderId, '') AS varchar(100))
			                                        + '@ItemMasterId = ''' + CAST(ISNULL(@ItemMasterId, '') AS varchar(100)) 
													+ '@SerialNumber = ''' + CAST(ISNULL(@SerialNumber, '') AS varchar(100)) 
													+ '@ConditionId = ''' + CAST(ISNULL(@ConditionId, '') AS varchar(100)) 
													+ '@MasterCompanyId = ''' + CAST(ISNULL(@MasterCompanyId, '') AS varchar(100)) 													
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------------------------------------
              exec spLogException 
                       @DatabaseName           = @DatabaseName
                     , @AdhocComments          = @AdhocComments
                     , @ProcedureParameters	   = @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID                    = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
	END CATCH
END