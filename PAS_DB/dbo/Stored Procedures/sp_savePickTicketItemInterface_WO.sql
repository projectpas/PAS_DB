CREATE PROCEDURE [dbo].[sp_savePickTicketItemInterface_WO]
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
  @StocklineId bigint
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
			IF (@IsMPN = 1)
			BEGIN
				INSERT INTO [dbo].[WOPickTicket]
					  ([PickTicketNumber], [WorkorderId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate],[IsActive],[IsDeleted],[WorkFlowWorkOrderId],[OrderPartId],
					   [Qty],[QtyToShip],[MasterCompanyId],[Status]
					  ,[PickedById],[ConfirmedById],[Memo],[IsConfirmed])
				VALUES(@WOPickTicketNumber, @WorkOrderId, @CreatedBy, @UpdatedBy, GETDATE(), GETDATE(), @IsActive, @IsDeleted, @WorkOrderMaterialsId,@WorkOrderMaterialsId,
						@Qty, @QtyToShip, @MasterCompanyId, @Status,
						@PickedById, @ConfirmedById, @Memo, @IsConfirmed);
			END
			ELSE
			BEGIN
				INSERT INTO [dbo].[WorkorderPickTicket]
					  ([PickTicketNumber], [WorkorderId], [CreatedBy], [UpdatedBy], [CreatedDate] ,[UpdatedDate],[IsActive],[IsDeleted],[WorkOrderMaterialsId],[OrderPartId],
					   [Qty],[QtyToShip],[MasterCompanyId],[Status], [StocklineId]
					  ,[PickedById],[ConfirmedById],[Memo],[IsConfirmed])
				VALUES(@WOPickTicketNumber, @WorkOrderId,  @CreatedBy, @UpdatedBy, GETDATE(), GETDATE(), @IsActive, @IsDeleted, @WorkOrderMaterialsId,@WorkOrderMaterialsId,
						@Qty, @QtyToShip, @MasterCompanyId, @Status, @StocklineId,
						@PickedById, @ConfirmedById, @Memo, @IsConfirmed);
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
			END
			ELSE
			BEGIN
				UPDATE [dbo].[WorkorderPickTicket] SET QtyToShip = @QtyToShip, UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE PickTicketId = @WOPickTicketId;
			END
		END
		ELSE IF(@WOPickTicketId > 0 AND @IsConfirmed = 1)
		BEGIN
			IF (@IsMPN = 1)
			BEGIN
				UPDATE [dbo].[WOPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETDATE() WHERE PickTicketId = @WOPickTicketId;
			END
			ELSE
			BEGIN
				UPDATE [dbo].[WorkorderPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETDATE() WHERE PickTicketId = @WOPickTicketId;
			END
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