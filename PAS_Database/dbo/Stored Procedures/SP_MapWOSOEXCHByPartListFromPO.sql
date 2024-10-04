/*************************************************************           
 ** File:   [SP_MapWOSOEXCHByPartListFromPO]           
 ** Author:  Rajesh Gami
 ** Description: This stored procedure is used to Map WO,SO,EXCH,LOT from the PO 
 ** Purpose:         
 ** Date:   03/Oct/2024     
 ** RETURN VALUE:           
 **************************************************************           
 ** Change History           
 **************************************************************           
 ** PR   Date         Author					Change Description            
 ** --   --------     -------				--------------------------------          
    1    03/Oct/2024   RAJESH GAMI			Created

************************************************************************/
CREATE   PROCEDURE [dbo].[SP_MapWOSOEXCHByPartListFromPO]
	@userName varchar(50) = NULL,
	@masterCompanyId bigint = NULL,
	@tbl_PurchaseOrderPartWOSOEXCHType PurchaseOrderPartWOSOEXCHType READONLY
AS
BEGIN
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
		
	BEGIN TRY
		BEGIN TRANSACTION
		BEGIN -->>>>> Start: Main Transaction 

			DECLARE @TotalPartsCount int = 0, @PartLoopId int = 1,@ManagementStructureId BIGINT;
			DECLARE @NewPartId BIGINT = 0, @PurchaseOrderPartRecordId BIGINT,@PurchaseOrderId BIGINT, @LotId BIGINT, @WorkOrderId BIGINT;
			DECLARE @SalesOrderId BIGINT,@SubWorkOrderId BIGINT,@RequestedQtyFromWO INT = 0,@ExchangeSalesOrderId BIGINT 
			DECLARE @WOModuleId INT = 1, @SOModuleId INT = 3, @ExchModuleId INT = 4, @SubWOModuleId INT = 5, @LOTModuleId INT = 6
			DECLARE @POPartRecordCount INT = 0,@QuantityOrdered INT =0,@IsFromSubWorkOrder BIT = 0;
			IF OBJECT_ID(N'tempdb..#tmpPoPartList') IS NOT NULL    
			BEGIN    
				DROP TABLE #tmpPoPartList
			END
			
			SELECT * INTO #tmpPoPartList FROM (SELECT * FROM @tbl_PurchaseOrderPartWOSOEXCHType) AS partResult

			SET @TotalPartsCount = (SELECT COUNT(1) FROM #tmpPoPartList)

			WHILE @PartLoopId <= @TotalPartsCount
			BEGIN -->>>>> Start: While Loop Main
				SELECT @PurchaseOrderId = PurchaseOrderId,@PurchaseOrderPartRecordId = PurchaseOrderPartRecordId,@LotId = LotId,@WorkOrderId = WorkOrderId,
					   @SalesOrderId = SalesOrderId,@SubWorkOrderId = SubWorkOrderId,@RequestedQtyFromWO = RequestedQtyFromWO,@ExchangeSalesOrderId = ExchangeSalesOrderId,
					   @QuantityOrdered = QuantityOrdered,@IsFromSubWorkOrder = IsFromSubWorkOrder
				FROM #tmpPoPartList WHERE PoPartSrNum = @PartLoopId;
				SET @POPartRecordCount = (SELECT COUNT(PurchaseOrderPartRecordId) FROM DBO.PurchaseOrderPart WITH (NOLOCK) WHERE PurchaseOrderPartRecordId = @PurchaseOrderPartRecordId);
------------------------ START: Work Order Mapping ----------------------------------
				IF(ISNULL(@WorkOrderId,0) > 0 AND ISNULL(@SubWorkOrderId,0) = 0 AND ISNULL(@RequestedQtyFromWO,0) > 0)
				BEGIN 
					IF(@POPartRecordCount > 0)
					BEGIN
						IF((SELECT COUNT(PurchaseOrderPartReferenceId) FROM DBO.PurchaseOrderPartReference WITH (NOLOCK) WHERE PurchaseOrderPartId = @PurchaseOrderPartRecordId AND ReferenceId = @WorkOrderId  AND ModuleId = @WOModuleId) > 0)
						BEGIN
							UPDATE PurchaseOrderPartReference SET UpdatedDate = GETUTCDATE(), UpdatedBy = @userName 
								   WHERE PurchaseOrderPartId = @PurchaseOrderPartRecordId AND ReferenceId = @WorkOrderId AND ModuleId = @WOModuleId
						END
						ELSE
						BEGIN
								INSERT INTO [dbo].[PurchaseOrderPartReference]
										   ([PurchaseOrderId]
										   ,[PurchaseOrderPartId]
										   ,[ModuleId]
										   ,[ReferenceId]
										   ,[Qty]
										   ,[RequestedQty]
										   ,[MasterCompanyId]
										   ,[CreatedBy]
										   ,[UpdatedBy]
										   ,[CreatedDate]
										   ,[UpdatedDate]
										   ,[IsActive]
										   ,[IsDeleted])
									 VALUES
										   (@PurchaseOrderId
										   ,@PurchaseOrderPartRecordId
										   ,@WOModuleId
										   ,@WorkOrderId
										   ,@RequestedQtyFromWO
										   ,@RequestedQtyFromWO
										   ,@masterCompanyId
										   ,@userName
										   ,@userName
										   ,GETUTCDATE()
										   ,GETUTCDATE()
										   ,1
										   ,0)

						END
					END
				END
------------------------ END: Work Order Mapping ----------------------------------

------------------------ START: SalesOrder Mapping ----------------------------------
				IF(ISNULL(@SalesOrderId,0) >0)
				BEGIN
					IF(@POPartRecordCount > 0)
					BEGIN
						INSERT INTO [dbo].[PurchaseOrderPartReference]
										   ([PurchaseOrderId]
										   ,[PurchaseOrderPartId]
										   ,[ModuleId]
										   ,[ReferenceId]
										   ,[Qty]
										   ,[MasterCompanyId]
										   ,[CreatedBy]
										   ,[UpdatedBy]
										   ,[CreatedDate]
										   ,[UpdatedDate]
										   ,[IsActive]
										   ,[IsDeleted])
									 VALUES
										   (@PurchaseOrderId
										   ,@PurchaseOrderPartRecordId
										   ,@SOModuleId
										   ,@SalesOrderId
										   ,@QuantityOrdered
										   ,@masterCompanyId
										   ,@userName
										   ,@userName
										   ,GETUTCDATE()
										   ,GETUTCDATE()
										   ,1
										   ,0)
					END
				END

------------------------ END: SalesOrder Mapping ----------------------------------

------------------------ START: ExchangeSalesOrder Mapping ----------------------------------
				IF(ISNULL(@ExchangeSalesOrderId,0) >0)
				BEGIN
					IF(@POPartRecordCount > 0)
					BEGIN
						INSERT INTO [dbo].[PurchaseOrderPartReference]
									([PurchaseOrderId]
									,[PurchaseOrderPartId]
									,[ModuleId]
									,[ReferenceId]
									,[Qty]
									,[MasterCompanyId]
									,[CreatedBy]
									,[UpdatedBy]
									,[CreatedDate]
									,[UpdatedDate]
									,[IsActive]
									,[IsDeleted])
								VALUES
									(@PurchaseOrderId
									,@PurchaseOrderPartRecordId
									,@ExchModuleId
									,@ExchangeSalesOrderId
									,@QuantityOrdered
									,@masterCompanyId
									,@userName
									,@userName
									,GETUTCDATE()
									,GETUTCDATE()
									,1
									,0)				
					END
				END
------------------------ END: ExchangeSalesOrder Mapping ----------------------------------

------------------------ START: SubWorkOrder Mapping ----------------------------------
				IF(ISNULL(@SubWorkOrderId,0) >0)
				BEGIN
					IF(@POPartRecordCount > 0)
					BEGIN
						INSERT INTO [dbo].[PurchaseOrderPartReference]
									([PurchaseOrderId]
									,[PurchaseOrderPartId]
									,[ModuleId]
									,[ReferenceId]
									,[Qty]
									,[MasterCompanyId]
									,[CreatedBy]
									,[UpdatedBy]
									,[CreatedDate]
									,[UpdatedDate]
									,[IsActive]
									,[IsDeleted])
								VALUES
									(@PurchaseOrderId
									,@PurchaseOrderPartRecordId
									,@SubWOModuleId
									,@SubWorkOrderId
									,CASE WHEN ISNULL(@IsFromSubWorkOrder,0) = 1 THEN @RequestedQtyFromWO ELSE @QuantityOrdered END
									,@masterCompanyId
									,@userName
									,@userName
									,GETUTCDATE()
									,GETUTCDATE()
									,1
									,0)				
					END
				END
------------------------ END: SubWorkOrder Mapping ----------------------------------

------------------------ START: LOT Mapping ----------------------------------
				IF(ISNULL(@LotId,0) >0)
				BEGIN
					IF(@POPartRecordCount > 0)
					BEGIN
						INSERT INTO [dbo].[PurchaseOrderPartReference]
									([PurchaseOrderId]
									,[PurchaseOrderPartId]
									,[ModuleId]
									,[ReferenceId]
									,[Qty]
									,[MasterCompanyId]
									,[CreatedBy]
									,[UpdatedBy]
									,[CreatedDate]
									,[UpdatedDate]
									,[IsActive]
									,[IsDeleted])
								VALUES
									(@PurchaseOrderId
									,@PurchaseOrderPartRecordId
									,@LOTModuleId
									,@LotId
									,@QuantityOrdered
									,@masterCompanyId
									,@userName
									,@userName
									,GETUTCDATE()
									,GETUTCDATE()
									,1
									,0)				
					END
				END
------------------------ END: LOT Mapping ----------------------------------
				SET @PartLoopId +=1
			END -->>>>> End: While Loop Main

		END -->>>>> End: Main Transaction 
		COMMIT  TRANSACTION
	END TRY    
	BEGIN CATCH      
	SELECT ERROR_NUMBER() AS ErrorNumber,ERROR_STATE() AS ErrorState, ERROR_SEVERITY() AS ErrorSeverity,ERROR_PROCEDURE() AS ErrorProcedure, ERROR_LINE() AS ErrorLine,ERROR_MESSAGE() AS ErrorMessage;
		IF @@trancount > 0
			PRINT 'ROLLBACK'
			ROLLBACK TRAN;
			DECLARE   @ErrorLogID  INT, @DatabaseName VARCHAR(100) = db_name() 
-----------------------------------PLEASE CHANGE THE VALUES FROM HERE TILL THE NEXT LINE----------------------------------------
            , @AdhocComments     VARCHAR(150)    = 'SP_MapWOSOEXCHByPartListFromPO'             
			, @ProcedureParameters VARCHAR(3000) = '@userName = ''' + CAST(ISNULL(@userName, '') AS VARCHAR(100))+ 
			'@masterCompanyId = ''' + CAST(ISNULL(@masterCompanyId, '') AS VARCHAR(100))
            , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------
            exec spLogException 
                    @DatabaseName           = @DatabaseName
                    , @AdhocComments          = @AdhocComments
                    , @ProcedureParameters = @ProcedureParameters
                    , @ApplicationName        =  @ApplicationName
                    , @ErrorLogID             = @ErrorLogID OUTPUT ;
            RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1, @ErrorLogID)
            RETURN(1);
	END CATCH
END