/*************************************************************             
 ** File:   [sp_savePickTicketItemInterface_WO]             
 ** Author:     
 ** Description: This SP is Used to save pick ticket details      
 ** Purpose:           
 ** Date:     
            
 ** PARAMETERS:      
           
 ** RETURN VALUE:          
   
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------  
 1    03/29/2023   Vishal Suthar		Added IsKitType for KIT Changes  
 2    04/02/2023   Amit Ghediya			 Added WO History   
 3    08/18/2023   Devendra 			 Added QtyRemaining for wopickticket insert and update   
 4    08/21/2023   Amit Ghediya          Updated HitoryText content 
 4    09/18/2023   Devendra Shekh        pick ticket qty issue resovled 
  
 EXECUTE sp_savePickTicketItemInterface_WO 828,0  
**************************************************************/   
CREATE   PROCEDURE [dbo].[sp_savePickTicketItemInterface_WO]  
(      
  @WOPickTicketId bigint = 0,  
  @WOPickTicketNumber varchar(100)='',  
  @WorkOrderId bigint=0,  
  @CreatedBy varchar(100)='',  
  @UpdatedBy varchar(100)='',  
  @IsActive bit =0,  
  @IsDeleted bit =0,  
  @WorkOrderMaterialsId bigint=0,  
  @Qty int = 0,  
  @QtyToShip int=0,  
  @MasterCompanyId int=0,  
  @Status int=0,  
  @PickedById int=0,  
  @ConfirmedById int=0,  
  @Memo varchar(MAX)='',  
  @IsConfirmed bit=0,  
  @CodePrefixId bigint,  
  @CurrentNummber bigint = 0,  
  @IsMPN bit,  
  @StocklineId bigint,  
  @IsKitType bit  
)      
AS      
BEGIN     
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  

		DECLARE @QtyRemaining BIGINT,@WOMPN VARCHAR(150),@WOMitemmasterid BIGINT
			,@HistoryWorkOrderMaterialsId BIGINT,@historyModuleId BIGINT,@historySubModuleId BIGINT  
			,@TemplateBody NVARCHAR(MAX),@WorkOrderNum VARCHAR(MAX),@StockLineNum VARCHAR(MAX),@WorkFlowWorkOrderId BIGINT
			,@WorkOrderPartNoId BIGINT,@ItemMasterId BIGINT,@partnumber VARCHAR(200),@PNItemMasterId BIGINT,@RevisedItemmasterid BIGINT, @TotalWMSTK BIGINT
			,@TotalShipQty BIGINT, @WOWorkFlowId BIGINT,@WOPartNoId BIGINT;

		SET @WOWorkFlowId = (SELECT WorkFlowWorkOrderId FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId);
		SET @WOPartNoId = (SELECT WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WOWorkFlowId);

		IF(@WOPickTicketId = 0)  
		BEGIN  
		   IF (@IsMPN = 1)  
		   BEGIN  
				SELECT @QtyRemaining = (ISNULL(wop.Quantity, 0) - @QtyToShip - SUM(ISNULL(wopt.QtyToShip, 0))) 
				FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
				LEFT JOIN [dbo].[WOPickTicket] wopt WITH(NOLOCK) ON wop.WorkOrderId = wopt.WorkOrderId and wopt.OrderPartId = wop.ID
				WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID = @WOPartNoId GROUP BY wop.Quantity

				INSERT INTO [dbo].[WOPickTicket]  
				   ([PickTicketNumber], [WorkorderId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate],[IsActive],[IsDeleted],[WorkFlowWorkOrderId],[OrderPartId],  
					[Qty],[QtyToShip],[MasterCompanyId],[Status]  
				   ,[PickedById],[ConfirmedById],[Memo],[IsConfirmed],[QtyRemaining])  
				VALUES(@WOPickTicketNumber, @WorkOrderId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), @IsActive, @IsDeleted, @WorkOrderMaterialsId,@WorkOrderMaterialsId,  
				  @Qty, @QtyToShip, @MasterCompanyId, @Status,  
				  @PickedById, @ConfirmedById, @Memo, @IsConfirmed,@QtyRemaining);  
		   END  
		   ELSE  
		   BEGIN  
				IF(@IsKitType = 0)
				BEGIN
					SELECT @TotalWMSTK = Count(wmsl.WorkOrderMaterialsId) FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId
					INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 					 
					INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.WorkOrderMaterialsId
				END
				ELSE
				BEGIN
					SELECT @TotalWMSTK = Count(wmsl.WorkOrderMaterialsKitId) FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId
					INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.WorkOrderMaterialsKitId
				END

				IF(@IsKitType = 0)
				BEGIN
					SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
					FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
					LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId
				END
				ELSE
				BEGIN
					SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
					FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
					LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsKitId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId
				END
				IF (@TotalWMSTK > 1)
				BEGIN
					IF(@IsKitType = 0)
					BEGIN
						;WITH RESULT(QtyRemaining)AS (
						SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty) AS QtyRemaining
						FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
						INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
						INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
						WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId)--GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

						SELECT @QtyRemaining = QtyRemaining FROM RESULT;
					END
					ELSE
					BEGIN
						;WITH RESULT(QtyRemaining)AS (
						SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty) AS QtyRemaining
						FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
						INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
						INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
						WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId)--GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

						SELECT @QtyRemaining = QtyRemaining FROM RESULT;
					END
				END
				ELSE
				BEGIN
					IF(@IsKitType = 0)
					BEGIN
						;WITH RESULT(QtyRemaining)AS (
						SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty) AS QtyRemaining
						FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
						INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
						INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
						WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

						SELECT @QtyRemaining = QtyRemaining FROM RESULT;
					END
					ELSE
					BEGIN
						;WITH RESULT(QtyRemaining)AS (
						SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty) AS QtyRemaining
						FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
						INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
						INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
						INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
						WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

						SELECT @QtyRemaining = QtyRemaining FROM RESULT;
					END
				END

				INSERT INTO [dbo].[WorkorderPickTicket]  
				   ([PickTicketNumber], [WorkorderId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate],[IsActive],[IsDeleted],[WorkOrderMaterialsId],[OrderPartId],  
					[Qty],[QtyToShip],[MasterCompanyId],[Status], [StocklineId]  
				   ,[PickedById],[ConfirmedById],[Memo],[IsConfirmed],[IsKitType], [QtyRemaining])  
				VALUES(@WOPickTicketNumber, @WorkOrderId,  @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), @IsActive, @IsDeleted, @WorkOrderMaterialsId,@WorkOrderMaterialsId,  
				  @Qty, @QtyToShip, @MasterCompanyId, @Status, @StocklineId,  
				  @PickedById, @ConfirmedById, @Memo, @IsConfirmed,@IsKitType,@QtyRemaining);  
		   END  
     
		   IF(@CodePrefixId > 0 AND @CurrentNummber > 0)  
		   BEGIN  
				UPDATE DBO.CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = @CodePrefixId;  
		   END  
	  END  
	  ELSE IF(@WOPickTicketId > 0 AND @IsConfirmed =0)  
	  BEGIN  
		   IF (@IsMPN = 1)  
		   BEGIN  
				UPDATE [dbo].[WOPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE PickTicketId = @WOPickTicketId;  

				SELECT @QtyRemaining = (ISNULL(wop.Quantity, 0) - SUM(ISNULL(wopt.QtyToShip, 0))) 
				FROM [dbo].[WorkOrderPartNumber] wop WITH(NOLOCK)
				LEFT JOIN [dbo].[WOPickTicket] wopt WITH(NOLOCK) ON wop.WorkOrderId = wopt.WorkOrderId and wopt.OrderPartId = wop.ID
				WHERE wop.WorkOrderId = @WorkOrderId AND wop.ID = @WOPartNoId GROUP BY wop.Quantity

				UPDATE [dbo].[WOPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE PickTicketId = @WOPickTicketId;  
		   END  
		   ELSE  
		   BEGIN  
			UPDATE [dbo].[WorkorderPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE(),[QtyRemaining] = @QtyRemaining WHERE PickTicketId = @WOPickTicketId;  
			
			IF(@IsKitType = 0)
			BEGIN
				SELECT @TotalWMSTK = Count(wmsl.WorkOrderMaterialsId) FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
				INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId  
				INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
				WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.WorkOrderMaterialsId;
			END
			ELSE
			BEGIN
				SELECT @TotalWMSTK = Count(wmsl.WorkOrderMaterialsKitId) FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
				INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
				INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
				WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.WorkOrderMaterialsKitId;
			END

			IF(@IsKitType = 0)
			BEGIN
				SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
				FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
				INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
				INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
				LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
				WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId
			END
			ELSE
			BEGIN
				SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
				FROM [dbo].WorkOrderPartNumber wop WITH(NOLOCK)
				INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
				INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
				INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
				LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsKitId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
				WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId
			END

			IF(@TotalWMSTK > 1)
			BEGIN
				IF(@IsKitType = 0)
				BEGIN
					;WITH RESULT(QtyRemaining) AS(
					SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0)) - @TotalShipQty) AS QtyRemaining
					FROM WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId  
					INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId ) --GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

					SELECT @QtyRemaining = QtyRemaining FROM RESULT;
				END
				ELSE
				BEGIN
					;WITH RESULT(QtyRemaining) AS(
					SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0)) - @TotalShipQty) AS QtyRemaining
					FROM WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId 
					INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId ) --GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

					SELECT @QtyRemaining = QtyRemaining FROM RESULT;
				END
			END
			ELSE 
			BEGIN
				IF(@IsKitType = 0)
				BEGIN
					;WITH RESULT(QtyRemaining) AS(
					SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0)) -@TotalShipQty) AS QtyRemaining
					FROM WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrderMaterials] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsId = wmsl.WorkOrderMaterialsId   
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

					SELECT @QtyRemaining = QtyRemaining FROM RESULT
				END
				ELSE
				BEGIN
					;WITH RESULT(QtyRemaining) AS(
					SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0)) -@TotalShipQty) AS QtyRemaining
					FROM WorkOrderPartNumber wop WITH(NOLOCK)
					INNER JOIN [dbo].[WorkOrderWorkFlow] wowf WITH(NOLOCK) ON wop.ID = wowf.WorkOrderPartNoId 
					INNER JOIN [dbo].[WorkOrderMaterialsKit] wom WITH(NOLOCK) ON wowf.WorkFlowWorkOrderId = wom.WorkFlowWorkOrderId
					INNER JOIN [dbo].[WorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.WorkOrderMaterialsKitId = wmsl.WorkOrderMaterialsKitId   
					WHERE wom.WorkOrderId = @WorkOrderId AND wom.WorkOrderMaterialsKitId = @WorkOrderMaterialsId AND wop.ID = @WOPartNoId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

					SELECT @QtyRemaining = QtyRemaining FROM RESULT;
				END
			END
	
			UPDATE [dbo].[WorkorderPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE(), [QtyRemaining] = @QtyRemaining WHERE PickTicketId = @WOPickTicketId;  
		   END  
	  END  
	  ELSE IF(@WOPickTicketId > 0 AND @IsConfirmed = 1)  
	  BEGIN  
		   IF (@IsMPN = 1)  
		   BEGIN  
			UPDATE [dbo].[WOPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETUTCDATE() WHERE PickTicketId = @WOPickTicketId;  
		   END  
		   ELSE  
		   BEGIN  
			UPDATE [dbo].[WorkorderPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETUTCDATE() WHERE PickTicketId = @WOPickTicketId;  
		   END  
	  END  
    
       --Added for WO History   
	   IF(@IsKitType = 0) -- For check is kit or not.
	   BEGIN
			IF(@IsMPN = 0)
			BEGIN
				 SELECT @IsKitType = IsKitType FROM [dbo].[WorkorderPickTicket] WITH(NOLOCK) WHERE PickTicketId = @WOPickTicketId;
			END
	   END
		
	   --Get Template text based on condition.
	   IF(@IsMPN = 0 AND @IsConfirmed = 0)
	   BEGIN
			SELECT @TemplateBody = TemplateBody FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'MaterialPicket';  
	   END
	   ELSE IF(@IsMPN = 0 AND @IsConfirmed = 1)
	   BEGIN 
			SELECT @TemplateBody = TemplateBody FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'MaterialPickticketConfirmed';  
	   END
	   ELSE IF(@IsMPN = 1 AND @IsConfirmed = 0)
	   BEGIN 
			SELECT @TemplateBody = TemplateBody FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'MPNPickticket';  
	   END
	   ELSE IF(@IsMPN = 1 AND @IsConfirmed = 1)
	   BEGIN 
			SELECT @TemplateBody = TemplateBody FROM [dbo].[HistoryTemplate] WITH(NOLOCK) WHERE TemplateCode = 'MPNPickticketConfirmed';  
	   END
	   
	   SELECT @historyModuleId = moduleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'WorkOrder';  
	   SELECT @historySubModuleId = moduleId FROM [dbo].[Module] WITH(NOLOCK) WHERE ModuleName = 'WorkOrderMPN';  

	   SELECT @WorkOrderNum = WorkOrderNum FROM [dbo].[WorkOrder] WITH(NOLOCK) WHERE WorkOrderId = @WorkOrderId;  
	   IF(@IsMPN = 1)  
	   BEGIN  
	   	    SELECT @WorkOrderPartNoId = ID,@PNItemMasterId = ItemMasterId,@RevisedItemmasterid = RevisedItemmasterid FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) 
			WHERE ID = @WorkOrderMaterialsId;  
			
			--Get from Revised if added
			IF(@RevisedItemmasterid > 0)
			BEGIN
				SET @PNItemMasterId = @RevisedItemmasterid;
			END
	   END  
	   ELSE  
	   BEGIN  
	   	IF(@IsKitType > 0)
	   	BEGIN
	   		SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId,@PNItemMasterId = ItemMasterId FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;  
	   		SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;  
	   		SELECT @ItemMasterId = ItemMasterId FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId;
	   	END
	   	ELSE
	   	BEGIN 
	   		SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId,@PNItemMasterId = ItemMasterId FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;  
	   		SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;  
	   		SELECT @ItemMasterId = ItemMasterId FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId;
	   	END
	   END  

	   IF(@PNItemMasterId > 0)
	   BEGIN
	   	    SELECT @partnumber = partnumber FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE ItemMasterId = @PNItemMasterId;
	   END
	   ELSE
	   BEGIN 
	   	IF (@IsMPN = 1)  
	   	BEGIN  
	   		SELECT @WOPickTicketNumber = PickTicketNumber,@WorkFlowWorkOrderId = WorkFlowWorkOrderId,@WorkOrderId = WorkorderId,@UpdatedBy = UpdatedBy FROM [dbo].[WOPickTicket] WITH(NOLOCK) WHERE PickTicketId = @WOPickTicketId;
	   		SELECT @PNItemMasterId = ItemMasterId,@RevisedItemmasterid = RevisedItemmasterid FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID = @WorkFlowWorkOrderId;
			
			--Get from Revised if added
			IF(@RevisedItemmasterid > 0)
			BEGIN
				SET @PNItemMasterId = @RevisedItemmasterid;
			END
			SET @WorkOrderPartNoId = @WorkFlowWorkOrderId;
	   	END  
	   	ELSE  
	   	BEGIN  
	   		SELECT @WOPickTicketNumber = PickTicketNumber,@WorkOrderMaterialsId = WorkOrderMaterialsId,@WorkOrderId = WorkorderId,@UpdatedBy = UpdatedBy FROM [dbo].[WorkorderPickTicket] WITH(NOLOCK) WHERE PickTicketId = @WOPickTicketId;
	   		IF(@IsKitType > 0)
	   		BEGIN 
	   			SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId,@PNItemMasterId = ItemMasterId FROM [dbo].[WorkOrderMaterialsKit] WITH(NOLOCK) WHERE WorkOrderMaterialsKitId = @WorkOrderMaterialsId;  
	   		END
	   		ELSE
	   		BEGIN 
	   			SELECT @WorkFlowWorkOrderId = WorkFlowWorkOrderId,@PNItemMasterId = ItemMasterId FROM [dbo].[WorkOrderMaterials] WITH(NOLOCK) WHERE WorkOrderMaterialsId = @WorkOrderMaterialsId;  
	   		END
	   		SELECT @WorkOrderPartNoId = WorkOrderPartNoId FROM [dbo].[WorkOrderWorkFlow] WITH(NOLOCK) WHERE WorkFlowWorkOrderId = @WorkFlowWorkOrderId;  
	   		SELECT @ItemMasterId = ItemMasterId FROM [dbo].[WorkOrderPartNumber] WITH(NOLOCK) WHERE ID = @WorkOrderPartNoId;
	   	END  
	   	SELECT @partnumber = partnumber FROM [dbo].[ItemMaster] WITH(NOLOCK) WHERE ItemMasterId = @PNItemMasterId;
	   END
	   
	   --Entry in History Table.
	   IF(@IsConfirmed = 0 AND @IsMPN = 0)
	   BEGIN
	   		SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@partnumber,'')); 
			EXEC [dbo].[USP_History] @historyModuleId,@WorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','Material Picked',@TemplateBody,'MaterialPicket',@MasterCompanyId,@UpdatedBy,NULL,@UpdatedBy,NULL;  
	   END
	   ELSE IF(@IsConfirmed = 1 AND @IsMPN = 0)
	   BEGIN 
	   		SET @TemplateBody = REPLACE(@TemplateBody, '##PN##', ISNULL(@partnumber,''));  
	   		EXEC [dbo].[USP_History] @historyModuleId,@WorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','Material Confirmed',@TemplateBody,'MaterialPickticketConfirmed',@MasterCompanyId,@UpdatedBy,NULL,@UpdatedBy,NULL;  
	   END
	   ELSE IF(@IsConfirmed = 0 AND @IsMPN = 1)
	   BEGIN 
	   		SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', ISNULL(@partnumber,''));  
			SET @TemplateBody = REPLACE(@TemplateBody, '##PickTicketNumber##', ISNULL(@WOPickTicketNumber,''));  
	   		EXEC [dbo].[USP_History] @historyModuleId,@WorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','MPN Picked',@TemplateBody,'MPNPickticket',@MasterCompanyId,@UpdatedBy,NULL,@UpdatedBy,NULL;  
	   END
	   ELSE IF(@IsConfirmed = 1 AND @IsMPN = 1)
	   BEGIN 
	   		SET @TemplateBody = REPLACE(@TemplateBody, '##MPN##', ISNULL(@partnumber,''));  
			SET @TemplateBody = REPLACE(@TemplateBody, '##PickTicketNumber##', ISNULL(@WOPickTicketNumber,''));  
	   		EXEC [dbo].[USP_History] @historyModuleId,@WorkOrderId,@historySubModuleId,@WorkOrderPartNoId,'','MPN Confirmed',@TemplateBody,'MPNPickticketConfirmed',@MasterCompanyId,@UpdatedBy,NULL,@UpdatedBy,NULL;  
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
            , @AdhocComments     VARCHAR(150)    = 'sp_savePickTicketItemInterface'   
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@WOPickTicketId, '') + ''  
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