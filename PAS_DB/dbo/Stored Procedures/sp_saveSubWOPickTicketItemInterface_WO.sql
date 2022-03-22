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
 ** PR   Date         Author		Change Description            
 ** --   --------     -------		--------------------------------          
    1    09/25/2021   Hemant Saliya Created
     
-- EXEC [sp_saveSubWOPickTicketItemInterface_WO] 46, 23, 343, 0

exec sp_saveSubWOPickTicketItemInterface_WO @WOPickTicketId=0,@WOPickTicketNumber=N'PTWO-001038',@WorkOrderId=60,@CreatedBy=N'Admin Admin',@UpdatedBy=N'Admin Admin',
@IsActive=1,@IsDeleted=0,@SubWorkOrderMaterialsId=49,@Qty=0,@QtyToShip=1,@MasterCompanyId=5,@Status=1,@PickedById=5,@ConfirmedById=0,@Memo='',@IsConfirmed=0,
@CodePrefixId=11,@CurrentNummber=1038,@IsMPN=0,@StocklineId=47,@SubWorkOrderId=40, @SubWorkorderPartNoId = 40

**************************************************************/
CREATE PROCEDURE [dbo].[sp_saveSubWOPickTicketItemInterface_WO]
(    
  @WOPickTicketId BIGINT = 0,
  @WOPickTicketNumber VARCHAR(100)='',
  @WorkOrderId BIGINT=0,
  @CreatedBy VARCHAR(100)='',
  @UpdatedBy VARCHAR(100)='',
  @IsActive BIT =0,
  @IsDeleted BIT =0,
  @SubWorkOrderMaterialsId BIGINT=0,
  @Qty INT = 0,
  @QtyToShip INT=0,
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
  @SubWorkorderPartNoId BIGINT=0
)    
AS    
BEGIN   
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		 IF(@WOPickTicketId = 0)
		 BEGIN
			PRINT 'Hi'
			INSERT INTO [dbo].[SubWorkorderPickTicket]
				  ([PickTicketNumber], [WorkorderId], [SubWorkorderId], [SubWorkorderPartNoId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate],[IsActive],[IsDeleted],[SubWorkOrderMaterialsId],[OrderPartId],
				   [Qty],[QtyToShip],[MasterCompanyId],[Status], [StocklineId]
				  ,[PickedById],[ConfirmedById],[Memo],[IsConfirmed])
			VALUES(@WOPickTicketNumber, @WorkOrderId, @SubWorkOrderId, @SubWorkorderPartNoId,  @CreatedBy, @UpdatedBy, GETDATE(), GETDATE(), @IsActive, @IsDeleted, @SubWorkOrderMaterialsId,@SubWorkOrderMaterialsId,
					@Qty, @QtyToShip, @MasterCompanyId, @Status, @StocklineId,
					@PickedById, @ConfirmedById, @Memo, @IsConfirmed);

			IF(@CodePrefixId > 0 AND @CurrentNummber > 0)
			BEGIN
				UPDATE DBO.CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = @CodePrefixId;
			END
		END
		ELSE IF(@WOPickTicketId > 0 AND @IsConfirmed =0)
		BEGIN
			UPDATE [dbo].[SubWorkorderPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE PickTicketId = @WOPickTicketId;
		END
		ELSE IF(@WOPickTicketId > 0 AND @IsConfirmed = 1)
		BEGIN
			UPDATE [dbo].[SubWorkorderPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETDATE() WHERE PickTicketId = @WOPickTicketId;
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