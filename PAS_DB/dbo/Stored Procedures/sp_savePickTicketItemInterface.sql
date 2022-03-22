﻿CREATE PROCEDURE [dbo].[sp_savePickTicketItemInterface]    
(    
  @SOPickTicketId bigint = 0,
  @SOPickTicketNumber varchar(100)='',
  @SalesOrderId bigint=0,
  @CreatedBy varchar(100)='',
  @UpdatedBy varchar(100)='',
  @IsActive bit =0,
  @IsDeleted bit =0,
  @SalesOrderPartId bigint=0,
  @Qty int = 0,
  @QtyToShip int=0,
  @MasterCompanyId int=0,
  @Status int=0,
  @PickedById int=0,
  @ConfirmedById int=0,
  @Memo varchar(MAX)='',
  @IsConfirmed bit=0,
  @CodePrefixId bigint,
  @CurrentNummber bigint = 0
)    
AS    
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN TRANSACTION
	BEGIN
		DECLARE @SOPartId BIGINT;

		IF(@SOPickTicketId = 0)
		BEGIN
			INSERT INTO [dbo].[SOPickTicket]
					([SOPickTicketNumber], [SalesOrderId], [CreatedBy], [UpdatedBy], [CreatedDate], [UpdatedDate], [IsActive],
					[IsDeleted], [SalesOrderPartId], [Qty], [QtyToShip], [MasterCompanyId], [Status],
					[PickedById], [ConfirmedById], [Memo], [IsConfirmed])
			VALUES(@SOPickTicketNumber, @SalesOrderId, @CreatedBy, @UpdatedBy, GETDATE(), GETDATE(), @IsActive, @IsDeleted, 
					@SalesOrderPartId,
					@Qty, @QtyToShip, @MasterCompanyId, @Status, @PickedById, @ConfirmedById, @Memo, @IsConfirmed);

			IF(@CodePrefixId > 0 AND @CurrentNummber > 0)
			BEGIN
				UPDATE DBO.CodePrefixes SET CurrentNummber = @CurrentNummber WHERE CodePrefixId = @CodePrefixId;
			END
		END
		ELSE IF(@SOPickTicketId > 0 AND @IsConfirmed = 0)
		BEGIN
			UPDATE [dbo].[SOPickTicket] SET QtyToShip = @QtyToShip,UpdatedBy = @UpdatedBy, UpdatedDate = GETDATE() WHERE SOPickTicketId = @SOPickTicketId;

			Update [dbo].[SalesOrderPart] SET StatusId = (SELECT SOPartStatusId FROM DBO.SOPartStatus WITH (NOLOCK) WHERE PartStatus = 'Picked') 
			WHERE SalesOrderPartId = @SalesOrderPartId
		END
		ELSE IF(@SOPickTicketId > 0 AND @IsConfirmed = 1)
		BEGIN
			UPDATE [dbo].[SOPickTicket] SET ConfirmedById = @ConfirmedById, IsConfirmed = @IsConfirmed, ConfirmedDate = GETDATE() WHERE SOPickTicketId = @SOPickTicketId;

			
			SELECT @SOPartId = SalesOrderPartId FROM [dbo].[SOPickTicket] WITH (NOLOCK) WHERE SOPickTicketId = @SOPickTicketId;

			Update [dbo].[SalesOrderPart] SET StatusId = (SELECT SOPartStatusId FROM DBO.SOPartStatus WITH (NOLOCK) WHERE PartStatus = 'ReadyForShip') 
			WHERE SalesOrderPartId = @SOPartId
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
            , @ProcedureParameters VARCHAR(3000)  = '@Parameter1 = '''+ ISNULL(@SOPickTicketId, '') + ''
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