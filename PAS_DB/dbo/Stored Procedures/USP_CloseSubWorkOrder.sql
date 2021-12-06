
/*************************************************************           
 ** File:   [USP_Reserve_ReleaseSubWorkOrderStockline]           
 ** Author:   Hemant Saliya
 ** Description: This stored procedure is used to Reserve Or Release Stockline for Sub WO   
 ** Purpose:         
 ** Date:   08/12/2021        
          
 ** PARAMETERS:           
 @WorkOrderId BIGINT   
 @WFWOId BIGINT  
         
 ** RETURN VALUE:           
  
 **************************************************************           
  ** Change History           
 **************************************************************           
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    08/12/2021   Hemant Saliya Created
     
 EXECUTE USP_CloseSubWorkOrder 415,72, 648,60,1

**************************************************************/ 
    
CREATE PROCEDURE [dbo].[USP_CloseSubWorkOrder]    
(    
@WorkOrderId  BIGINT  = NULL,
@SubWorkOrderId  BIGINT  = NULL,
@WorkOrderMaterialsId  BIGINT  = NULL,
@StocklineId  BIGINT  = NULL,
@UpdatedById BIGINT = NULL
)    
AS    
BEGIN    

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SET NOCOUNT ON    

	BEGIN TRY
		BEGIN TRANSACTION
			BEGIN

				DECLARE @SubWorkOrderStatusId BIGINT;
				DECLARE @ProvisionId BIGINT;
				DECLARE @MasterCompanyId BIGINT;
				DECLARE @PartStatusId INT;
				DECLARE @UpdatedBy VARCHAR(200);
				DECLARE @SubWOPartQty INT;
				DECLARE @ItemMasterId BIGINT;
				DECLARE @ConditionId BIGINT;
				DECLARE @SubWOQty INT;
				DECLARE @CurrentNo BIGINT;
				DECLARE @PickTicketNumber VARCHAR(100);
				DECLARE @CodeTypeId INT;
				DECLARE @WorkOrderTypeId INT;

				SELECT @UpdatedBy = FirstName + ' ' + LastName FROM dbo.Employee Where EmployeeId = @UpdatedById
				SET @PartStatusId = 3; -- WHEN RESERVE & ISSUE ID = 3
				SET @SubWOPartQty = 1; -- It's Always Single QTY
				SET @CodeTypeId = 44; -- For Pick Ticket
				SET @WorkOrderTypeId = 1 -- Customer WO Only

				IF OBJECT_ID(N'tempdb..#tmpResStockLine') IS NOT NULL
				BEGIN
				DROP TABLE #tmpResStockLine
				END
				
				IF OBJECT_ID(N'tempdb..#tmpPickTicket') IS NOT NULL
				BEGIN
				DROP TABLE #tmpPickTicket
				END

				IF OBJECT_ID(N'tempdb..#PickTicketGet') IS NOT NULL
				BEGIN
				DROP TABLE #PickTicketGet
				END

				IF OBJECT_ID(N'tempdb..#CodePrifix') IS NOT NULL
				BEGIN
				DROP TABLE #CodePrifix
				END
				
				CREATE TABLE #tmpResStockLine
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WorkOrderMaterialsId BIGINT NULL,
					 WOMStockLineId BIGINT NULL,
					 StockLineId BIGINT NULL,
					 QuantityIssued INT NULL,
					 QuantityReserved INT NULL,
					 UnitCost DECIMAL(18,2) NULL,
					 ExtendedCost DECIMAL(18,2) NULL,
					 ReservedById BIGINT NULL,
					 IssuedById BIGINT NULL,
					 IssuedDate DATETIME2(7) NULL,
					 UpdatedDate DATETIME2(7) NULL,
					 PartStatusId INT NULL,
					 ParentWorkOrderMaterialsId BIGINT NULL,
				)

				CREATE TABLE #PickTicketGet
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 PartNumber VARCHAR(500) NULL,
					 StocklineId BIGINT NULL,
					 PartId BIGINT NULL,
					 ItemMasterId BIGINT NULL,
					 [Description] VARCHAR(MAX) NULL,
					 ItemGroup VARCHAR(100) NULL,
					 Manufacturer VARCHAR(100) NULL,
					 ManufacturerId  BIGINT NULL,
					 ConditionId BIGINT NULL,
					 AlternetFor VARCHAR(100) NULL,
					 StockType VARCHAR(100) NULL,
					 StockLineNumber VARCHAR(100) NULL,
					 SerialNumber VARCHAR(100) NULL,
					 ControlNumber VARCHAR(100) NULL,
					 IdNumber VARCHAR(100) NULL,
					 QtyToPick INT NULL,
					 QtyToReserve INT NULL,
					 QtyAvailable INT NULL,
					 QtyOnHand INT NULL,
					 UnitCost DECIMAL(18,2) NULL,
					 TracableToName VARCHAR(100) NULL,
					 TagType VARCHAR(500) NULL,
					 TagDate DATETIME2(7) NULL,
					 CertifiedBy VARCHAR(500 ) NULL,
					 CertifiedDate DATETIME2(7) NULL,
					 Memo VARCHAR(MAX) NULL,
					 Method VARCHAR(200) NULL,
					 MethodType VARCHAR(100) NULL,
					 PMA BIT NULL,
					 StkLineManufacturer VARCHAR(200) NULL,
				)

				CREATE TABLE #tmpPickTicket
				(
					 ID BIGINT NOT NULL IDENTITY, 
					 WOPickTicketId BIGINT NULL,
					 WOPickTicketNumber VARCHAR(50) NULL,
					 WorkOrderId BIGINT NULL,
					 CreatedBy VARCHAR(50) NULL,
					 UpdatedBy VARCHAR(50) NULL,
					 IsActive BIT NULL,
					 IsDeleted BIT NULL,
					 WorkOrderMaterialsId BIGINT NULL,
					 Qty INT NULL,
					 QtyToShip INT NULL,
					 MasterCompanyId BIGINT NULL,
					 [Status] INT NULL,
					 PickedById BIGINT NULL,
					 ConfirmedById BIGINT NULL,
					 Memo VARCHAR(MAX) NULL,
					 IsConfirmed BIT NULL,
					 CodePrefixId BIGINT NULL,
					 CurrentNummber BIGINT NULL,
					 IsMPN BIT NULL,
					 StocklineId BIGINT NULL,
				)

				SELECT @SubWorkOrderStatusId  = Id FROM dbo.WorkOrderStatus WITH(NOLOCK) WHERE UPPER(StatusCode) = 'CLOSED'
				SELECT @ProvisionId  = ProvisionId FROM dbo.Provision WITH(NOLOCK) WHERE UPPER(StatusCode) = 'REPLACE'
				SELECT @MasterCompanyId  = MasterCompanyId FROM dbo.SubWorkOrder WITH(NOLOCK) WHERE SubWorkOrderId = @SubWorkOrderId

				IF((SELECT COUNT(1) FROM dbo.SubWorkOrderPartNumber WHERE SubWorkOrderId = @SubWorkOrderId AND SubWorkOrderStatusId <> @SubWorkOrderStatusId ) = 0)
					BEGIN
						SELECT @ItemMasterId = WOMS.ItemMasterId, @ConditionId = WOMS.ConditionId, @SubWOQty = WOMS.Quantity FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) 
							JOIN dbo.SubWorkOrder SWO WITH(NOLOCK) ON WOMS.WorkOrderMaterialsId = SWO.WorkOrderMaterialsId
							AND WOMS.StockLineId = SWO.StockLineId 
						WHERE SWO.SubWorkOrderId = @SubWorkOrderId AND SWO.WorkOrderId = @WorkOrderId

						--CASE IF ENFORE PICK TICKET IS THERE THEN CREATE PICK TICKET
						IF((SELECT COUNT(1) FROM dbo.WorkOrderSettings WHERE WorkOrderTypeId = @WorkOrderTypeId AND MasterCompanyId = @MasterCompanyId AND EnforcePickTicket = 1) > 0)
						BEGIN
							INSERT INTO #PickTicketGet(PartNumber,StocklineId,PartId,ItemMasterId,Description,ItemGroup,Manufacturer,ManufacturerId,ConditionId,AlternetFor,StockType,
							StockLineNumber,SerialNumber,ControlNumber,IdNumber,QtyToReserve,QtyToPick,QtyAvailable,QtyOnHand,UnitCost,TracableToName,TagType,TagDate,CertifiedBy,
							CertifiedDate,Memo,Method,MethodType,PMA,StkLineManufacturer)
							EXEC SearchPickTicketForSubWO @ItemMasterId, @ConditionId, @WorkOrderId , @StocklineId

							INSERT INTO #tmpPickTicket(WOPickTicketId, WorkOrderId, CreatedBy, UpdatedBy, IsActive, IsDeleted, WorkOrderMaterialsId, Qty
										, QtyToShip, MasterCompanyId, Status, PickedById, ConfirmedById, Memo, IsConfirmed, IsMPN, StocklineId)
							SELECT 0, @WorkOrderId, @UpdatedBy, @UpdatedBy, 1, 0, @WorkOrderMaterialsId, @SubWOQty
										, @SubWOQty, @MasterCompanyId, 1, @UpdatedById, @UpdatedById, Memo, 1, 0, StocklineId FROM #PickTicketGet

							SELECT * INTO #CodePrifix
							FROM dbo.CodePrefixes WITH(NOLOCK) WHERE IsActive = 1 AND IsDeleted = 0 AND MasterCompanyId = @MasterCompanyId AND CodeTypeId = @CodeTypeId -- 44 Fixed Code TYpe Values

							IF((SELECT CurrentNummber FROM #CodePrifix) <> 0)
							BEGIN
								SELECT @CurrentNo = ISNULL(CurrentNummber, 0) + 1 FROM #CodePrifix
							END
							ELSE
							BEGIN
								SELECT @CurrentNo = ISNULL(StartsFrom, 0) + 1 FROM #CodePrifix
							END

							IF((SELECT COUNT(1) FROM #CodePrifix) > 0)
							BEGIN
								SET @PickTicketNumber = (SELECT * FROM dbo.udfGenerateCodeNumber(@CurrentNo,ISNULL((SELECT CodePrefix FROM #CodePrifix),''),ISNULL((SELECT CodeSufix FROM #CodePrifix), '')))
							END

							UPDATE #tmpPickTicket SET CodePrefixId = @CodeTypeId, CurrentNummber = @CurrentNo , WOPickTicketNumber = @PickTicketNumber;
							
							INSERT INTO [dbo].[WorkorderPickTicket]
							  ([PickTicketNumber], [WorkorderId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate],[IsActive],[IsDeleted],[WorkOrderMaterialsId],[OrderPartId],
							   [Qty],[QtyToShip],[MasterCompanyId],[Status], [StocklineId] ,[PickedById],[ConfirmedById],[Memo],[IsConfirmed])
							SELECT WOPickTicketNumber, WorkOrderId,  CreatedBy, UpdatedBy, GETDATE(), GETDATE(), IsActive, IsDeleted, WorkOrderMaterialsId, @WorkOrderMaterialsId,
							Qty, QtyToShip, @MasterCompanyId, [Status], StocklineId,PickedById, ConfirmedById, Memo, IsConfirmed FROM #tmpPickTicket;

							UPDATE CodePrefixes SET CurrentNummber = @CurrentNo WHERE CodeTypeId = @CodeTypeId AND MasterCompanyId = @MasterCompanyId;

						END

						UPDATE dbo.WorkOrderMaterialStockLine SET ProvisionId = @ProvisionId WHERE StockLineId = @StocklineId AND WorkOrderMaterialsId = @WorkOrderMaterialsId;

						INSERT INTO #tmpResStockLine (WorkOrderMaterialsId,StockLineId, WOMStockLineId, QuantityIssued,QuantityReserved,PartStatusId, ParentWorkOrderMaterialsId, UnitCost, ExtendedCost)
							SELECT WOMS.WorkOrderMaterialsId,StockLineId, WOMS.WOMStockLineId, WOMS.Quantity,0, @PartStatusId, WOM.ParentWorkOrderMaterialsId,  WOM.UnitCost,  WOM.ExtendedCost
						FROM dbo.WorkOrderMaterialStockLine WOMS WITH(NOLOCK) JOIN dbo.WorkOrderMaterialS WOM ON WOMS.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId
						WHERE StockLineId = @StocklineId AND WOMS.WorkOrderMaterialsId = @WorkOrderMaterialsId AND WOMS.ProvisionId = @ProvisionId
						
						UPDATE WorkOrderMaterials 
							SET TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityIssued,0)								
						FROM dbo.WorkOrderMaterials WOM JOIN #tmpResStockLine tmpWOM ON WOM.WorkOrderMaterialsId = tmpWOM.ParentWorkOrderMaterialsId 

						UPDATE WorkOrderMaterials 
							SET QuantityIssued = ISNULL(WOM.QuantityIssued,0) + ISNULL(tmpWOM.QuantityIssued,0),
								TotalIssued = ISNULL(WOM.TotalIssued,0) + ISNULL(tmpWOM.QuantityIssued,0),
								ReservedById = @UpdatedById, ReservedDate = GETDATE(), IssuedById = @UpdatedById, UpdatedDate = GETDATE(),
								PartStatusId = tmpWOM.PartStatusId, ParentWorkOrderMaterialsId = tmpWOM.ParentWorkOrderMaterialsId
						FROM dbo.WorkOrderMaterials WOM JOIN #tmpResStockLine tmpWOM ON tmpWOM.WorkOrderMaterialsId = WOM.WorkOrderMaterialsId

						IF((SELECT COUNT(1) FROM #tmpResStockLine WHERE QuantityIssued > 0) > 0)
						BEGIN
							UPDATE StockLine 
								SET QuantityAvailable = ISNULL(SL.QuantityAvailable,0) - ISNULL(tmpWOM.QuantityIssued,0),
									QuantityOnHand = ISNULL(SL.QuantityOnHand,0) - ISNULL(tmpWOM.QuantityIssued,0), 
									QuantityIssued = ISNULL(SL.QuantityIssued,0) - ISNULL(tmpWOM.QuantityIssued,0),
									UpdatedDate = GETDATE(), UpdatedBy = @UpdatedBy, WorkOrderMaterialsId = tmpWOM.WorkOrderMaterialsId
							FROM dbo.StockLine SL JOIN #tmpResStockLine tmpWOM ON SL.StockLineId = tmpWOM.StockLineId 
							WHERE SL.StockLineId = @StocklineId
						END

						UPDATE WorkOrderMaterialStockLine 
							SET QtyIssued = ISNULL(WOMS.QtyIssued,0) + ISNULL(tmpWOM.QuantityIssued,0),
								UnitCost = ISNULL(tmpWOM.UnitCost,0), 
								ExtendedCost = ISNULL(tmpWOM.UnitCost,0) * (ISNULL(WOMS.QtyIssued,0) + ISNULL(tmpWOM.QuantityIssued,0)),
								UnitPrice = ISNULL(tmpWOM.UnitCost,0), 
								ExtendedPrice = ISNULL(tmpWOM.UnitCost,0) * (ISNULL(WOMS.QtyIssued,0) + ISNULL(tmpWOM.QuantityIssued,0)),
								UpdatedDate = GETDATE(), UpdatedBy = @UpdatedBy
						FROM dbo.WorkOrderMaterialStockLine WOMS JOIN #tmpResStockLine tmpWOM ON WOMS.WOMStockLineId = tmpWOM.WOMStockLineId
						WHERE WOMS.StockLineId = @StocklineId AND WOMS.WorkOrderMaterialsId = @WorkOrderMaterialsId
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
              , @AdhocComments     VARCHAR(150)    = 'USP_CloseSubWorkOrder' 
              , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = ' + ISNULL(@WorkOrderId, '') + ',
													   @Parameter2 = ' + ISNULL(@SubWorkOrderId,'') + ', 
													   @Parameter3 = ' + ISNULL(@WorkOrderMaterialsId,'') + ', 
													   @Parameter4 = ' + ISNULL(@StocklineId ,'') +''
              , @ApplicationName VARCHAR(100) = 'PAS'
-----------------------------------PLEASE DO NOT EDIT BELOW----------------------------------------

              exec spLogException 
                       @DatabaseName			= @DatabaseName
                     , @AdhocComments			= @AdhocComments
                     , @ProcedureParameters		= @ProcedureParameters
                     , @ApplicationName			= @ApplicationName
                     , @ErrorLogID              = @ErrorLogID OUTPUT ;
              RAISERROR ('Unexpected Error Occured in the database. Please let the support team know of the error number : %d', 16, 1,@ErrorLogID)
              RETURN(1);
		END CATCH
END