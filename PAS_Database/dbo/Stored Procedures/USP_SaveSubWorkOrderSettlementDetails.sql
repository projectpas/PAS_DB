/*************************************************************           
 ** File:   [USP_SaveSubWorkOrderSettlementDetails]           
 ** Author:   Devendra Shekh
 ** Description: used to save the sub workorder settlement Details
 ** Date:   15-April-2025        
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date				Author					Change Description            
 ** --   --------			-------					--------------------------------          
    1    15-April-2025		Devendra Shekh			Created
**************************************************************/
CREATE   PROCEDURE [dbo].[USP_SaveSubWorkOrderSettlementDetails]
	@WorkOrderId BIGINT = 0,
	@SubWOPartNoId BIGINT = 0,
	@SubWorkOrderId BIGINT = 0,
	@MasterCompanyId INT = 0,
	@CreatedBy VARCHAR(256) = ''
AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;
		BEGIN TRY

			DECLARE @WO_Act_vs_WO_Qte_Reviewed VARCHAR(200) = 'WO ACTUAL V/S WO QUOTE REVIEWED';
			DECLARE @Parts_Shipped VARCHAR(200) = 'UNIT SHIPPED';
			DECLARE @Parts_Invoiced VARCHAR(200) = 'WORK ORDER INVOICED';

			DECLARE @CurrenctSettlementId BIGINT = 0, @MaxSettlementId BIGINT = 0;

			IF OBJECT_ID('tempdb..#WorkOrderSettlement') IS NOT NULL
				DROP TABLE #WorkOrderSettlement

			SELECT * INTO #WorkOrderSettlement
			FROM [dbo].[WorkOrderSettlement] WITH(NOLOCK)
			WHERE ISNULL(IsDeleted, 0) = 0 AND UPPER([WorkOrderSettlementName]) NOT IN (@WO_Act_vs_WO_Qte_Reviewed, @Parts_Shipped, @Parts_Invoiced) 

			SELECT @CurrenctSettlementId = MIN([WorkOrderSettlementId]), @MaxSettlementId = MAX([WorkOrderSettlementId]) FROM #WorkOrderSettlement

			WHILE(ISNULL(@MaxSettlementId, 0) >= ISNULL(@CurrenctSettlementId, 0))
			BEGIN
				
				INSERT INTO [dbo].[SubWorkOrderSettlementDetails] ([WorkOrderId], [SubWorkOrderId], [SubWOPartNoId], [WorkOrderSettlementId],
							[MasterCompanyId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive], [IsDeleted], [IsMastervalue], [Isvalue_NA], [Memo], [ConditionId],
							[UserId], [UserName], [sattlement_DateTime], [conditionName], [RevisedItemmasterid])
				SELECT	@WorkOrderId, @SubWorkOrderId, @SubWOPartNoId, [WorkOrderSettlementId], @MasterCompanyId, @CreatedBy, @CreatedBy, GETUTCDATE(), GETUTCDATE(), 1, 0, 0, 0, NULL, NULL,
						NULL, NULL, NULL, NULL, NULL
				FROM #WorkOrderSettlement WHERE [WorkOrderSettlementId] = @CurrenctSettlementId

				SET @CurrenctSettlementId += 1;
			END
	
		END TRY    
		BEGIN CATCH      
			IF @@trancount > 0
				PRINT 'ROLLBACK'
				DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 

-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
              , @AdhocComments     VARCHAR(150)    = 'USP_SaveSubWorkOrderSettlementDetails' 
			  , @ProcedureParameters VARCHAR(3000) = ''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName           =  @DatabaseName
                     , @AdhocComments          =  @AdhocComments
                     , @ProcedureParameters	   =  @ProcedureParameters
                     , @ApplicationName        =  @ApplicationName
                     , @ErrorLogID             =  @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH

END