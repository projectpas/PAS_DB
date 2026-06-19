/*************************************************************             
 ** File:   [sp_saveSubWOPickTicketItemInterface_WO]             
 ** Author:   Hemant Saliya  
 ** Description: This SP is Used Save Sub WO Pick Ticket Details    
 ** Purpose:           
 ** Date:   09/25/2021          
            
 ** PARAMETERS:             
 @UserType varchar(60)     
           
 ** RETURN VALUE:             
    
 **************************************************************             
  ** Change History             
 **************************************************************             
 ** PR   Date         Author			Change Description              
 ** --   --------     -------			--------------------------------            
    1    09/25/2021   Hemant Saliya			Created  
    2    08/09/2023   Bhargav Saliya		Conver Date(Created & Updated) In UTC
	3    08/18/2023   Devendra 				Added QtyRemaining for wopickticket insert and update   
	4    09/20/2023   Devendra Shekh        pick ticket qty issue resovled 
	5    12/19/2023   Devendra Shekh        changes for kit part added
	6    12/21/2023   Devendra Shekh        QTY issue resolved
 ***7    16/Mar/2026  Rajesh Gami			Added UOM Changes [PN-15714]   
	8	 19/06/2026	  Ayushi				[PN-16911]Skip fn_ConvertUOM call when ToUOM = FromUOM
-- EXEC [sp_saveSubWOPickTicketItemInterface_WO] 46, 23, 343, 0  
  
exec sp_saveSubWOPickTicketItemInterface_WO @WOPickTicketId=0,@WOPickTicketNumber=N'PTWO-001038',@WorkOrderId=60,@CreatedBy=N'Admin Admin',@UpdatedBy=N'Admin Admin',  
@IsActive=1,@IsDeleted=0,@SubWorkOrderMaterialsId=49,@Qty=0,@QtyToShip=1,@MasterCompanyId=5,@Status=1,@PickedById=5,@ConfirmedById=0,@Memo='',@IsConfirmed=0,  
@CodePrefixId=11,@CurrentNummber=1038,@IsMPN=0,@StocklineId=47,@SubWorkOrderId=40, @SubWorkorderPartNoId = 40  
  
**************************************************************/  
CREATE   PROCEDURE [dbo].[sp_saveSubWOPickTicketItemInterface_WO]  
(      
  @WOPickTicketId BIGINT = 0,  
  @WOPickTicketNumber VARCHAR(100)='',  
  @WorkOrderId BIGINT=0,  
  @CreatedBy VARCHAR(100)='',  
  @UpdatedBy VARCHAR(100)='',  
  @IsActive BIT =0,  
  @IsDeleted BIT =0,  
  @SubWorkOrderMaterialsId BIGINT=0,  
  @Qty  decimal(18,6) = 0,  
  @QtyToShip  decimal(18,6)=0,  
  @MasterCompanyId INT=0,  
  @Status INT=0,  
  @PickedById INT=0,  
  @ConfirmedById INT=0,  
  @Memo VARCHAR(MAX)='',  
  @IsConfirmed BIT=0,  
  @CodePrefixId BIGINT,  
  @CurrentNummber BIGINT = 0,  
  @IsMPN BIT,  
  @StocklineId BIGINT,  
  @SubWorkOrderId BIGINT=0,  
  @SubWorkorderPartNoId BIGINT=0,
  @IsKitType bit = 0
)      
AS      
BEGIN     
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  

  DECLARE @QtyRemaining  decimal(18,6), @TotalWMSTK  decimal(18,6),@TotalShipQty  decimal(18,6);
			/************ START: UOM Changes Logic : Rajesh Gami *************/
			IF(ISNULL(@IsMPN,0) = 0)
			BEGIN
				DECLARE	@StockUnitOfMeasure VARCHAR(100), @ConsumeUnitOfMeasure VARCHAR(100);
				SELECT @StockUnitOfMeasure  = su.ShortCode,
					   @ConsumeUnitOfMeasure = cu.ShortCode
				FROM DBO.Stockline sl WITH (NOLOCK)
					LEFT JOIN DBO.UnitOfMeasure su WITH (NOLOCK) ON sl.StockUnitOfMeasureId = su.UnitOfMeasureId
					LEFT JOIN DBO.UnitOfMeasure cu WITH (NOLOCK) ON sl.ConsumeUnitOfMeasureId = cu.UnitOfMeasureId
				WHERE sl.StockLineId = @StocklineId;

				IF (@ConsumeUnitOfMeasure IS NOT NULL 
					AND @StockUnitOfMeasure IS NOT NULL
					AND ISNULL(@ConsumeUnitOfMeasure,'') <> ISNULL(@StockUnitOfMeasure,''))
				BEGIN
					IF (@Qty > 0)
						SET @Qty = dbo.fn_ConvertUOM(@Qty, @ConsumeUnitOfMeasure, @StockUnitOfMeasure, 0, @MasterCompanyId);

					IF (@QtyToShip > 0)
						SET @QtyToShip = dbo.fn_ConvertUOM(@QtyToShip, @ConsumeUnitOfMeasure, @StockUnitOfMeasure, 0, @MasterCompanyId);
				END
			END			
			/************ END: UOM Changes Logic *************/

   IF(@WOPickTicketId = 0)  
   BEGIN  
   PRINT 'Hi'  

	IF(@IsKitType = 0)
	BEGIN
		SELECT @TotalWMSTK = Count(wmsl.SubWorkOrderMaterialsId) 
		FROM [dbo].[SubWorkOrderMaterials] wom WITH(NOLOCK) 
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId      
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId GROUP BY wmsl.SubWorkOrderMaterialsId
	END
	ELSE
	BEGIN
		print 'kit type'
		SELECT @TotalWMSTK = Count(wmsl.SubWorkOrderMaterialsKitId) 
		FROM [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) 
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId      
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId GROUP BY wmsl.SubWorkOrderMaterialsKitId
	END

	IF(@IsKitType = 0)
	BEGIN
		SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
		FROM [SubWorkOrderMaterials] wom WITH(NOLOCK)
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId   
		LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON  wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
	END
	ELSE
	BEGIN
		print 'kit type'
		print @TotalWMSTK
		SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
		FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
		INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
		LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.SubWorkOrderMaterialsKitId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId
	END	   
   
   print @TotalWMSTK
	IF (@TotalWMSTK > 1)
	BEGIN
		IF(@IsKitType = 0)
		BEGIN			
			;WITH RESULT(QtyRemaining)AS (
   			SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty)  as QtyRemaining
			FROM [SubWorkOrderMaterials] wom WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId   
			--LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON  wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId) --GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT;
		END
		ELSE
		BEGIN
			print 'kit type'
			;WITH RESULT(QtyRemaining)AS (
			SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty) AS QtyRemaining
			FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId )--GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT;
		END
	END
	ELSE
	BEGIN
		IF(@IsKitType = 0)
		BEGIN			
			;WITH RESULT(QtyRemaining)AS (
   			SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty)  as QtyRemaining
			FROM [SubWorkOrderMaterials] wom WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId   
			--LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON  wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT;
		END
		ELSE
		BEGIN
			;WITH RESULT(QtyRemaining)AS (
			SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0))  - @QtyToShip - @TotalShipQty) AS QtyRemaining
			FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT;
		END				
	END
	print @QtyRemaining
   INSERT INTO [dbo].[SubWorkorderPickTicket]  
      ([PickTicketNumber], [WorkorderId], [SubWorkorderId], [SubWorkorderPartNoId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate],[IsActive],[IsDeleted],[SubWorkOrderMaterialsId],[OrderPartId],  
       [Qty],[QtyToShip],[MasterCompanyId],[Status], [StocklineId]  
      ,[PickedById],[ConfirmedById],[Memo],[IsConfirmed], [QtyRemaining], [IsKitType])  
   VALUES(@WOPickTicketNumber, @WorkOrderId, @SubWorkOrderId, @SubWorkorderPartNoId,  @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), @IsActive, @IsDeleted, @SubWorkOrderMaterialsId,@SubWorkOrderMaterialsId,  
     @Qty, @QtyToShip, @MasterCompanyId, @Status, @StocklineId,  
     @PickedById, @ConfirmedById, @Memo, @IsConfirmed, @QtyRemaining, @IsKitType);  
  
   IF(@CodePrefixId > 0 AND @CurrentNummber > 0)  
   BEGIN  
    UPDATE DBO.CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = @CodePrefixId;  
   END  
  END  
  ELSE IF(@WOPickTicketId > 0 AND @IsConfirmed =0)  
  BEGIN  
   UPDATE [dbo].[SubWorkorderPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE() WHERE PickTicketId = @WOPickTicketId;  

	IF(@IsKitType = 0)
	BEGIN
		SELECT @TotalWMSTK = Count(wmsl.SubWorkOrderMaterialsId) 
		FROM [dbo].[SubWorkOrderMaterials] wom WITH(NOLOCK) 
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId      
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId GROUP BY wmsl.SubWorkOrderMaterialsId
	END
	ELSE
	BEGIN
		SELECT @TotalWMSTK = Count(wmsl.SubWorkOrderMaterialsKitId) FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
		INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId GROUP BY wmsl.SubWorkOrderMaterialsKitId;
	END
	
	IF(@IsKitType = 0)
	BEGIN
		SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
		FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
		INNER JOIN [dbo].[SubWorkOrderMaterials] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId   
		LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.SubWorkOrderMaterialsId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId
	END
	ELSE
	BEGIN
		SELECT @TotalShipQty = SUM(ISNULL(wopt.QtyToShip, 0))
		FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
		INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
		INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
		LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.SubWorkOrderMaterialsKitId = wopt.SubWorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
		WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId
	END

	IF (@TotalWMSTK > 1)
	BEGIN
		IF(@IsKitType = 0)
		BEGIN
			;WITH RESULT(QtyRemaining) AS(
			SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0)) - @TotalShipQty) AS QtyRemaining
			FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterials] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId   
			--LEFT JOIN [dbo].[SubWorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId ) --GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT;
		END
		ELSE
		BEGIN
			;WITH RESULT(QtyRemaining) AS(
			SELECT (SUM(ISNULL(wmsl.QtyReserved, 0)) + SUM(ISNULL(wmsl.QtyIssued, 0)) - @TotalShipQty) AS QtyRemaining
			FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId ) --GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT;
		END		
	END
	ELSE
	BEGIN
		IF(@IsKitType = 0)
		BEGIN
			;WITH RESULT(QtyRemaining) AS(
			SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0)) - @TotalShipQty) AS QtyRemaining
			FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterials] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLine] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsId = wmsl.SubWorkOrderMaterialsId   
			--LEFT JOIN [dbo].[WorkorderPickTicket] wopt WITH(NOLOCK) ON wom.WorkOrderId = wopt.WorkOrderId and wom.WorkOrderMaterialsId = wopt.WorkOrderMaterialsId AND wopt.StocklineId = wmsl.StockLineId
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsId = @SubWorkOrderMaterialsId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT
		END
		ELSE
		BEGIN
			;WITH RESULT(QtyRemaining) AS(
			SELECT ((ISNULL(wmsl.QtyReserved, 0)) + (ISNULL(wmsl.QtyIssued, 0)) - @TotalShipQty) AS QtyRemaining
			FROM SubWorkOrderPartNumber wop WITH(NOLOCK)
			INNER JOIN [dbo].[SubWorkOrderMaterialsKit] wom WITH(NOLOCK) ON wop.WorkOrderId = wom.WorkOrderId AND wop.SubWOPartNoId = wom.SubWOPartNoId 
			INNER JOIN [dbo].[SubWorkOrderMaterialStockLineKit] wmsl WITH(NOLOCK) ON wom.SubWorkOrderMaterialsKitId = wmsl.SubWorkOrderMaterialsKitId   
			WHERE wom.WorkOrderId = @WorkOrderId AND wom.SubWorkOrderMaterialsKitId = @SubWorkOrderMaterialsId GROUP BY wmsl.QtyReserved,wmsl.QtyIssued)

			SELECT @QtyRemaining = QtyRemaining FROM RESULT;
		END
	END

   UPDATE [dbo].[SubWorkorderPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETUTCDATE(),[QtyRemaining] = @QtyRemaining WHERE PickTicketId = @WOPickTicketId;  
  END  
  ELSE IF(@WOPickTicketId > 0 AND @IsConfirmed = 1)  
  BEGIN  
   UPDATE [dbo].[SubWorkorderPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETUTCDATE() WHERE PickTicketId = @WOPickTicketId;  
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
            , @AdhocComments     VARCHAR(150)    = 'sp_saveSubWOPickTicketItemInterface_WO'   
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