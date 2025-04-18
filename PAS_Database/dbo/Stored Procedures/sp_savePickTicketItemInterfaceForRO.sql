/********************************************************************************   
** Author:     Vishal Suthar
** Create date:  
** Description: This SP is Used to save pick ticket details   

**************************************************************************** 
** Change History 
****************************************************************************
** PR   Date		Author				Change Description  
** --   --------	-------				-----------------------------------
** 1    15-04-2025  Vishal Suthar	    Created

exec sp_savePickTicketItemInterfaceForRO @SOPickTicketId=0,@SOPickTicketNumber=N'PT(SO)-000742',@SalesOrderId=1570,@CreatedBy=N'Jim Roberts',@UpdatedBy=N'Jim Roberts',@IsActive=1,@IsDeleted=0,@SalesOrderPartId=1973,@SalesOrderStocklineId=2517,@Qty=0,@QtyToShip=1,@MasterCompanyId=1,@Status=1,@PickedById=55,@ConfirmedById=0,@Memo=default,@IsConfirmed=0,@CodePrefixId=17,@CurrentNummber=742
********************************************************************************/
CREATE   PROCEDURE [dbo].[sp_savePickTicketItemInterfaceForRO]      
(      
  @ROPickTicketId BIGINT = 0,  
  @ROPickTicketNumber VARCHAR(100) = '',  
  @RepairOrderId BIGINT = 0,  
  @CreatedBy VARCHAR(100)='',
  @UpdatedBy VARCHAR(100)='',
  @IsActive BIT = 0,
  @IsDeleted BIT = 0,
  @RepairOrderPartId BIGINT = 0,
  @StocklineId BIGINT = 0,
  @Qty INT = 0,
  @QtyToShip INT = 0,
  @MasterCompanyId INT = 0,
  @Status INT = 0,
  @PickedById INT = 0,
  @ConfirmedById INT = 0,
  @Memo VARCHAR(MAX) = '',
  @IsConfirmed BIT = 0,
  @CodePrefixId BIGINT,
  @CurrentNummber BIGINT = 0
)      
AS      
BEGIN  
 SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
 SET NOCOUNT ON;  
  
 BEGIN TRY  
 BEGIN TRANSACTION  
 BEGIN  
  DECLARE @ROPartId BIGINT;  
  DECLARE @QtyRemaining BIGINT = 0, @TotalRervePart BIGINT = 0; 
  DECLARE @EnforcePickTicketConfirmation BIT;

  IF(@ROPickTicketId = 0)  
  BEGIN  
	SELECT @EnforcePickTicketConfirmation = EnforcePickTicketConfirmation FROM DBO.RepairOrder WITH (NOLOCK) WHERE RepairOrderId = @RepairOrderId;

	SELECT @TotalRervePart = COUNT(RepairOrderPartRecordId) FROM dbo.RepairOrderPart rop WITH(NOLOCK) WHERE rop.RepairOrderId = @RepairOrderId

	IF(@TotalRervePart > 1)
	BEGIN
	    DECLARE @QtyToReserve INT = 0,@TotalQtyToShip INT = 0;

		SELECT @QtyToReserve = ISNULL(SUM(rop.QuantityReserved), 0) 
     	FROM dbo.RepairOrderPart rop WITH(NOLOCK)
		WHERE rop.RepairOrderId = @RepairOrderId AND rop.RepairOrderPartRecordId = @RepairOrderPartId		
		
		SELECT @TotalQtyToShip = ISNULL(SUM(ropt.QtyToShip),0) 
			FROM dbo.RepairOrderPart rop WITH(NOLOCK)
			LEFT JOIN dbo.ROPickTicket ropt WITH(NOLOCK) ON ropt.RepairOrderId = rop.RepairOrderId AND ropt.StocklineId = rop.StocklineId
			WHERE rop.RepairOrderId = @RepairOrderId AND rop.RepairOrderPartRecordId = @RepairOrderPartId;

		SET	@QtyRemaining = (@QtyToReserve - ISNULL(@QtyToShip,0) - @TotalQtyToShip) 
	END
	ELSE
	BEGIN	   
		SELECT @QtyRemaining = (rop.QuantityReserved - ISNULL(@QtyToShip,0) - SUM(ISNULL(ropt.QtyToShip, 0))) 
		FROM dbo.RepairOrderPart rop WITH(NOLOCK)
		LEFT JOIN dbo.ROPickTicket ropt WITH(NOLOCK) ON ropt.RepairOrderId = rop.RepairOrderId AND ropt.StocklineId = rop.StocklineId
		WHERE rop.RepairOrderId = @RepairOrderId AND rop.RepairOrderPartRecordId = @RepairOrderPartId GROUP BY rop.QuantityReserved
	END

   INSERT INTO [dbo].[ROPickTicket]  
     ([ROPickTicketNumber], [RepairOrderId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive],  
     [IsDeleted], [RepairOrderPartId], [StocklineId], [Qty], [QtyToShip], [MasterCompanyId], [Status],  
     [PickedById], [ConfirmedById], [Memo], [IsConfirmed], [QtyRemaining])  
   VALUES(@ROPickTicketNumber, @RepairOrderId, @CreatedBy, @UpdatedBy, GETUTCDATE(), GETUTCDATE(), @IsActive, @IsDeleted,   
     @RepairOrderPartId, @StocklineId,  
     @Qty, @QtyToShip, @MasterCompanyId, @Status, @PickedById, @ConfirmedById, @Memo, @IsConfirmed,@QtyRemaining);  
	
	SELECT @ROPickTicketId = SCOPE_IDENTITY()  

	IF (ISNULL(@EnforcePickTicketConfirmation, 0) = 0)
	BEGIN
		UPDATE [dbo].[ROPickTicket] SET ConfirmedById = @PickedById, IsConfirmed = 1, ConfirmedDate = GETUTCDATE() WHERE ROPickTicketId = @ROPickTicketId;
	END

	IF(@CodePrefixId > 0 AND @CurrentNummber > 0)  
	BEGIN  
		UPDATE DBO.CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = @CodePrefixId;  
	END  
  END  
  ELSE IF(@ROPickTicketId > 0 AND @IsConfirmed = 0)  
  BEGIN  
   UPDATE [dbo].[ROPickTicket] SET QtyToShip = @QtyToShip,UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE ROPickTicketId = @ROPickTicketId; 

   	SELECT @TotalRervePart = COUNT(RepairOrderPartRecordId) 
	FROM RepairOrderPart rop WITH(NOLOCK)
	WHERE rop.RepairOrderId = @RepairOrderId

	IF(@TotalRervePart > 1)
	BEGIN
		SELECT @QtyRemaining = (SUM(rop.QuantityReserved) - SUM(ISNULL(ropt.QtyToShip, 0))) 
		FROM RepairOrderPart rop WITH(NOLOCK)
		LEFT JOIN ROPickTicket ropt WITH(NOLOCK) ON ropt.RepairOrderId = rop.RepairOrderId and ropt.RepairOrderPartId = rop.RepairOrderPartRecordId
		WHERE rop.RepairOrderId = @RepairOrderId
	END
	ELSE
	BEGIN
		SELECT @QtyRemaining = (rop.QuantityReserved - SUM(ISNULL(ropt.QtyToShip, 0))) 
		FROM RepairOrderPart rop WITH(NOLOCK)
		LEFT JOIN ROPickTicket ropt WITH(NOLOCK) ON ropt.RepairOrderId = rop.RepairOrderId and ropt.RepairOrderPartId = rop.RepairOrderPartRecordId
		WHERE rop.RepairOrderPartRecordId = @RepairOrderPartId GROUP BY rop.QuantityReserved
	END
	

	UPDATE [dbo].[ROPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE(), [QtyRemaining] = @QtyRemaining  WHERE ROPickTicketId = @ROPickTicketId;
  END  
  ELSE IF (@ROPickTicketId > 0 AND @IsConfirmed = 1)  
  BEGIN  
	UPDATE [dbo].[ROPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETUTCDATE() WHERE ROPickTicketId = @ROPickTicketId;
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
            , @AdhocComments     VARCHAR(150)    = 'sp_savePickTicketItemInterfaceForRO'   
			, @ProcedureParameters VARCHAR(3000) = '@Parameter1 = ''' + CAST(ISNULL(@ROPickTicketId, '') AS VARCHAR(100))  
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