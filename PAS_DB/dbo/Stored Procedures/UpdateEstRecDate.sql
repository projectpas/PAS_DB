
CREATE PROC [dbo].[UpdateEstRecDate]
	@ModuleName VARCHAR(50),
	@RefId  BIGINT,
	@NextEstDate DATETIME,
	@UpdatedBy VARCHAR(100)
AS
BEGIN
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
		BEGIN
			IF (@ModuleName = 'PO')
			BEGIN
				UPDATE DBO.PurchaseOrderPart 
				SET EstDeliveryDate = @NextEstDate,
				UpdatedDate = GETDATE(), UpdatedBy = @UpdatedBy
				WHERE PurchaseOrderPartRecordId = @RefId

				UPDATE DBO.WorkOrderMaterials
				SET PONextDlvrDate = @NextEstDate
				FROM dbo.PurchaseOrderPart POP
				INNER JOIN dbo.WorkOrderMaterials WOM ON WOM.WorkOrderId = POP.WorkOrderId 
							AND WOM.ConditionCodeId = POP.ConditionId 
							AND wom.ItemMasterId = POP.ItemMasterId
				INNER JOIN dbo.PurchaseOrder P ON P.PurchaseOrderId = POP.PurchaseOrderId
				WHERE POP.PurchaseOrderPartRecordId = @RefId 
						AND POP.isParent = 1 
						AND POP.WorkOrderId > 0 
						and ISNULL(POP.SubWorkOrderId, 0)  = 0
			END
			ELSE IF (@ModuleName = 'RO')
			BEGIN
				UPDATE DBO.RepairOrderPart 
				SET EstRecordDate = @NextEstDate,
				UpdatedDate = GETDATE(), UpdatedBy = @UpdatedBy
				WHERE RepairOrderPartRecordId = @RefId

				UPDATE DBO.WorkOrderMaterials
				SET PONextDlvrDate = @NextEstDate
				FROM dbo.RepairOrderPart ROP
				INNER JOIN dbo.WorkOrderMaterials WOM ON WOM.WorkOrderId = ROP.WorkOrderId 
							AND WOM.ConditionCodeId = ROP.ConditionId 
							AND wom.ItemMasterId = ROP.ItemMasterId
				INNER JOIN dbo.RepairOrder R ON R.RepairOrderId = ROP.RepairOrderId
				WHERE ROP.RepairOrderPartRecordId = @RefId 
						AND ROP.isParent = 1 
						AND ROP.WorkOrderId > 0 
						and ISNULL(ROP.SubWorkOrderId, 0)  = 0
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
            , @AdhocComments     VARCHAR(150)    = 'UpdateEstRecDate' 
            , @ProcedureParameters VARCHAR(3000) = '@Parameter1 = '''+ ISNULL(@ModuleName, '') + ''',
													@Parameter2 = ' + ISNULL(@RefId, '') + ', 
													@Parameter3 = ' + ISNULL(@NextEstDate, '') +''
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments        = @AdhocComments
                    , @ProcedureParameters  = @ProcedureParameters
                    , @ApplicationName      =  @ApplicationName
                    , @ErrorLogID           = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
            RETURN(1);
	END CATCH
END